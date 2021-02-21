# Authorization server (TS | Node | Apollo | Hasura)
* Aimed at Hasura but can be used for any JWT/refresh-token set up
* Written in Typescript for NodeJS using Apollo to talk to a Hasura backend for the users database

## Backend users database
This authorization server relies on a Hasura database with a users table with the fields id, username, password (hashed), role, and (optionally) roles.

example:
```
{
    "id": 1,
    "password": "$2a$07$kb9OZxMnfTBKWk69KNgDQ.ZGv9DxPA0NEoO1QDAlJi90w4x9v78G",
    "role": "super-user",
    "roles": [
        "user",
        "super-user"
    ],
    "username": "Dad"
},
```
There are also sample hasura PSQL dump and metadata JSON files in `src/database` you can use to create a users database quickly

## To use
```
git clone https://github.com/timbophillips/hasura-auth-server.git
cd hasura-auth-server/
npm install
```
create a .env file (using example.env as a template) to point to your hasura server, then ...
```
npm start
```

## API

### GET /login
* Expects a GET request including standard HTTP Authorization headers 
* Read more about that at https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization
* Checks these credentials with the attached Hasura database..
* Responds with a signed JWT in body and a refresh token as an HTTP-only cookie.
* This is designed to work with Hasura Cloud when using JWT authentication
* Read more at https://hasura.io/docs/1.0/graphql/core/auth/authentication/jwt.html

Test with HTTPie:
```
http --session=/var/tmp/session.json --auth Mum:password -v GET localhost:3000/login
```
Output:
```
GET /login HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Authorization: Basic TXVtOnBhc3N3b3Jk
Connection: keep-alive
Host: localhost:3000
User-Agent: HTTPie/1.0.3

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 413
Content-Type: text/html; charset=utf-8
Date: Sun, 21 Feb 2021 05:06:44 GMT
ETag: W/"19d-6WcJPDvXSfFE+1GEq7VQz/osVAc"
Keep-Alive: timeout=5
Set-Cookie: refresh-token=j%3A%7B%22ip%22%3A%22%3A%3Affff%3A127.0.0.1%22%2C%22expires%22%3A%222021-02-28T05%3A06%3A43.202%2B00%3A00%22%2C%22token%22%3A%22f7a03c6f2c40b21139a9c88bd5782167359ee4df399a678c9c3da798f277ee928fb9ad149e9c7bf6%22%2C%22user%22%3A2%2C%22__typename%22%3A%22refresh_tokens%22%7D; Max-Age=2592000; Path=/; Expires=Tue, 23 Mar 2021 05:06:44 GMT; HttpOnly
X-Powered-By: Express

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsic3VwZXItdXNlciJdLCJ4LWhhc3VyYS1kZWZhdWx0LXJvbGUiOiJzdXBlci11c2VyIiwieC1oYXN1cmEtcm9sZSI6InN1cGVyLXVzZXIiLCJ4LWhhc3VyYS11c2VyLWlkIjoiMiJ9LCJjcmVhdGVkQnlJcCI6Ijo6ZmZmZjoxMjcuMC4wLjEiLCJzdWIiOiIyIiwiaWQiOiIyIiwiaWF0IjoxNjEzODg0MDAzLCJleHAiOjE2MTM4ODQ5MDN9.Sb980Wk03wVJt7mrKt6eMEHkeqPonEpOPLJUcR-_2cA
```
### GET /refresh
* Expects a GET request with a refresh token incuded as a HTTP-only cookie
* Body of request is ignored.
* Responds with a new JWT and new refresh token (in same format as with GET /login)

Test with HTTPie (after doing above test which will save the refresh token cookie in a json file):
```
http --session=/var/tmp/session.json -b GET localhost:3000/refresh
```
Output:
```
GET /refresh HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Authorization: Basic TXVtOnBhc3N3b3Jk
Connection: keep-alive
Cookie: refresh-token=j%3A%7B%22ip%22%3A%22%3A%3Affff%3A127.0.0.1%22%2C%22expires%22%3A%222021-02-28T05%3A10%3A55.023%2B00%3A00%22%2C%22token%22%3A%22060354ff70ad2709074157c0a4ff929086872649e5f853bc1921b3eac583fb65054e7b111af920de%22%2C%22user%22%3A2%2C%22__typename%22%3A%22refresh_tokens%22%7D
Host: localhost:3000
User-Agent: HTTPie/1.0.3

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 413
Content-Type: text/html; charset=utf-8
Date: Sun, 21 Feb 2021 05:11:02 GMT
ETag: W/"19d-VUhguGdkSlLF4FpkyIU5dYr9HHw"
Keep-Alive: timeout=5
Set-Cookie: refresh-token=j%3A%7B%22ip%22%3A%22%3A%3Affff%3A127.0.0.1%22%2C%22expires%22%3A%222021-02-28T05%3A11%3A00.993%2B00%3A00%22%2C%22token%22%3A%2212a31559ccb0218a74f550f43961ce01bf4af871699e818c3e64b080d0697cb706dcad79d253a992%22%2C%22user%22%3A2%2C%22__typename%22%3A%22refresh_tokens%22%7D; Max-Age=2592000; Path=/; Expires=Tue, 23 Mar 2021 05:11:02 GMT; HttpOnly
X-Powered-By: Express

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2hhc3VyYS5pby9qd3QvY2xhaW1zIjp7IngtaGFzdXJhLWFsbG93ZWQtcm9sZXMiOlsic3VwZXItdXNlciJdLCJ4LWhhc3VyYS1kZWZhdWx0LXJvbGUiOiJzdXBlci11c2VyIiwieC1oYXN1cmEtcm9sZSI6InN1cGVyLXVzZXIiLCJ4LWhhc3VyYS11c2VyLWlkIjoiMiJ9LCJjcmVhdGVkQnlJcCI6Ijo6ZmZmZjoxMjcuMC4wLjEiLCJzdWIiOiIyIiwiaWQiOiIyIiwiaWF0IjoxNjEzODg0MjYwLCJleHAiOjE2MTM4ODUxNjB9.60sEHTKgNLbzVDur-BbREEDTA_h0kC0OF1E7rkumdgA
```
### Test that the provided JWT token works for accessing your Hasura database
Use HTTPie to test the JWT token with the Hasura database server
```
TOKEN=$(http --session=/var/tmp/session.json -b GET localhost:3000/refresh)
http -v POST $HASURA_SERVER_GRAPHQL_ENDPOINT Authorization:'Bearer '$(echo $TOKEN)  query="$GRAPHQL"
```

### GET /logout/:username
* Expects a GET request (body of request is ignored). 
* Deletes all the refresh tokens for the provided username.

Test with HTTPie:
```
http -v localhost:3000/logout/Mum
```
Output:
```
GET /logout/Mum HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: localhost:3000
User-Agent: HTTPie/1.0.3

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 143
Content-Type: application/json; charset=utf-8
Date: Sun, 21 Feb 2021 05:11:12 GMT
ETag: W/"8f-nfIe8VszZCkWdOIlHTcHseNxjO4"
Keep-Alive: timeout=5
X-Powered-By: Express

{
    "deleted-tokens": [
        {
            "__typename": "refresh_tokens",
            "token": "0bd96e258d1da233099064e61626b7053342e639ff7d0b8827b8351f89b1d6f7fec16d474b3c4be3"
        }
    ]
}
```


### POST /changepassword

* Expects a POST request including 
    * Standard HTTP Authorization headers (https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization)
    * JSON body with `{ 'newpassword' : 'MyNewPassword' }`

Test with HTTPie
```
http -v --auth Mum:password POST localhost:3000/changepassword newpassword=MyNewPassword
```
Output
```
POST /changepassword HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Authorization: Basic RGFkOnRlbXAtcGFzc3dvcmQ=
Connection: keep-alive
Content-Length: 27
Content-Type: application/json
Host: smacking-hasura-auth.herokuapp.com
User-Agent: HTTPie/1.0.3

{
    "newpassword": "password"
}

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 51
Content-Type: application/json; charset=utf-8
Date: Sun, 21 Feb 2021 13:23:52 GMT
Etag: W/"33-Xs3ZLNEcHehD3MxkJ19UxQSDdns"
Server: Cowboy
Via: 1.1 vegur
X-Powered-By: Express

{
    "message": "password for Dad successfully changed"
}
```

### /webhook
* Written to work with the Hasura webhook authorization option (for your Hasura database not the authorization database).
* Expects a GET request including standard HTTP Authorization headers 
* REad more about that at https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization
* These headers will have been forwarded by Hasura after a client request. 
* Read more at https://hasura.io/docs/1.0/graphql/core/auth/authentication/webhook.html

test with HTTPie:
```
http --auth Mum:password -v GET localhost:3000/webhook
```
Responds with hasura variables, for example (HTTPie output):
```
GET /webhook HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Authorization: Basic TXVtOnBhc3N3b3Jk
Connection: keep-alive
Host: localhost:3000
User-Agent: HTTPie/1.0.3

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 53
Content-Type: application/json; charset=utf-8
Date: Sun, 21 Feb 2021 04:55:42 GMT
ETag: W/"35-+Q3o1iDznRUfMpSQJeXwox+WfsY"
Keep-Alive: timeout=5
X-Powered-By: Express

{
    "X-Hasura-Role": "super-user",
    "X-Hasura-User-Id": "2"
}

```
