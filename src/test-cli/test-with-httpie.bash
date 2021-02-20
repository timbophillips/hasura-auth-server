#!/bin/bash

USERNAME=Mum
PASSWORD=password
GRAPHQL="{ users { id username } }"

# get a JWT by submitting username and password
# and save the session so that the refresh-token cookie 
# can be used for the next request
http --session=/var/tmp/session.json --auth Lucy:password -v GET localhost:3000/jwt

# check that the refresh token system is working with verbose output
http --session=/var/tmp/session.json -b GET localhost:3000/jwt/refresh

# do it again but this time save it to a variable
TOKEN=$(http --session=/var/tmp/session.json -b GET localhost:3000/jwt/refresh)

# now use that variable to make a GraphQL query
http -v POST https://smacking.hasura.app/v1/graphql Authorization:'Bearer '$TOKEN  query="{ users { id username } }"

# get a JWT by submitting username and password
# and save the session so that the refresh-token cookie 
# can be used for the next request
http --session=/var/tmp/session.json --auth $USERNAME:$PASSWORD -v GET localhost:3000/jwt

# check that the refresh token system is working with verbose output
http --session=/var/tmp/session.json -b GET localhost:3000/jwt/refresh

# do it again but this time save it to a variable
TOKEN=$(http --session=/var/tmp/session.json -b GET localhost:3000/jwt/refresh)

# now use that variable to make a GraphQL query
http -v POST https://smacking.hasura.app/v1/graphql Authorization:'Bearer '$(echo $TOKEN)  query="$GRAPHQL"
