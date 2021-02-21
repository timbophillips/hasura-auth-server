#!/bin/bash
bash $(dirname "$0")/test-script.bash localhost:3000 Dad password https://smacking.hasura.app/v1/graphql "{ users { id username } }"