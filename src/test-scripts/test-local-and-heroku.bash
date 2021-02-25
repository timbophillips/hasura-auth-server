#!/bin/bash -x
bash -x $(dirname "$0")/test-script.bash \
    localhost:3000 \
    Dad \
    password \
    https://smacking.hasura.app/v1/graphql \
    "{ users { id username } }"

bash -x $(dirname "$0")/test-script.bash \
    https://smacking-hasura-auth.herokuapp.com \
    Dad \
    password \
    https://smacking.hasura.app/v1/graphql \
    "{ users { id username } }"