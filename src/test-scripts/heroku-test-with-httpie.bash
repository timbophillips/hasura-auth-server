#!/bin/bash -x

SERVER=https://smacking-hasura-auth.herokuapp.com
USERNAME=Mum
PASSWORD=password
GRAPHQL="{ users { id username } }"

# login using the hasura webhooks method
# https://hasura.io/docs/1.0/graphql/core/auth/authentication/webhook.html
http --auth $USERNAME:$PASSWORD -v GET $SERVER/webhook

# now for the JWT techniques
# https://hasura.io/docs/1.0/graphql/core/auth/authentication/jwt.html

# get a JWT by submitting username and password
# and save the session so that the refresh-token cookie 
# can be used for the next request
http --session=/var/tmp/session.json --auth $USERNAME:$PASSWORD -v GET $SERVER/login

# check that the refresh token system is working with verbose output
http --session=/var/tmp/session.json -b GET $SERVER/refresh

# do it again but this time save it to a variable
TOKEN=$(http --session=/var/tmp/session.json -b GET $SERVER/refresh)

# now use that variable to make a GraphQL query
http -v POST https://smacking.hasura.app/v1/graphql Authorization:'Bearer '$(echo $TOKEN)  query="$GRAPHQL"

# Now delete all of that user's tokens
http -v $SERVER/logout/$USERNAME