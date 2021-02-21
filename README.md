### Authorization server written in Typescript | NodeJS | Apollo

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
## API

# /login
Expects a GET request including standard HTTP Authorization headers (https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization)

Checks these credentials with the attached Hasura database..

Responds with a signed JWT in body and a refresh token as an HTTP-only cookie.

Test with HTTPie:
```
http --session=/var/tmp/session.json --auth Mum:password -v GET localhost:3000/login
```
# /refresh
Expects a GET request with the same refresh token, and responds with a new JWT and new refresh token (in same format as above). Body of request is ignored.

Test with HTTPie (after doing above test which will save the refresh token cookie in a json file):
```
http --session=/var/tmp/session.json -b GET localhost:3000/refresh
```
# /logout/:username
Expects a GET request (body of request is ignored). Deletes all the refresh tokens for the provided username.

# /webhook
Written to work with the Hasura webhook authorization option (for your Hasura database not the authorization database). Expects a GET request including standard HTTP Authorization headers (https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization) which will have been forwarded by Hasura after a client request. 

Responds with hasura variables, for example:
```
{
    "X-Hasura-Role": "super-user",
    "X-Hasura-User-Id": "2"
}
```
test with HTTPie:
```
http --auth Mum:password -v GET localhost:3000/webhook
```