#!/bin/bash -x

# delete the (previously used) session file if it exists
rm -f /var/tmp/session.json

AUTH_SERVER=$1
USERNAME=$2
PASSWORD=$3
GRAPHQL_SERVER=$4
GRAPHQL_QUERY=$5

# login using the hasura webhooks method
# https://hasura.io/docs/1.0/graphql/core/auth/authentication/webhook.html
http --auth $USERNAME:$PASSWORD -v GET $AUTH_SERVER/webhook

# now for the JWT techniques
# https://hasura.io/docs/1.0/graphql/core/auth/authentication/jwt.html

# get a JWT by submitting username and password
# and save the session so that the refresh-token cookie 
# can be used for the next request
http --session=/var/tmp/session.json --auth $USERNAME:$PASSWORD -v GET $AUTH_SERVER/login

# check that the refresh token system is working with verbose output
http --session=/var/tmp/session.json -v GET $AUTH_SERVER/refresh

# do it again but this time save it to a variable
TOKEN=$(http --session=/var/tmp/session.json -b GET $AUTH_SERVER/refresh | jq -r '.jwt')

# now use that variable to make a GraphQL query
http -v POST $GRAPHQL_SERVER Authorization:'Bearer '$(echo $TOKEN)  query="$GRAPHQL_QUERY"

# Now delete all of that user's tokens
http -v $AUTH_SERVER/logout/$USERNAME

# Change the user's password
http -v --auth $USERNAME:$PASSWORD POST $AUTH_SERVER/changepassword newpassword=temp-password

# Change the user's password back again
http -v --auth $USERNAME:temp-password POST $AUTH_SERVER/changepassword newpassword=$PASSWORD