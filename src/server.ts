// Hasura webhook server

// test by using httpie
// http -v :3000/webhook --auth jessica:2114

// or test with Hasura Graphiql console
// ... adding a Request Header
// --> key = Authorization
// --> Value = Basic amVzc2ljYToyMTE0
// (which is base64 for jessica:2114)
// and then remove the hasura-collaborator-token Header
// (which is effectively using the admin secret key)

// Get environment values
// In development mode these will come from
// .env if the script to start is
//  node -r dotenv/config server.js
//  rather than node server.js
const port = process.env.PORT || 3000;

import { decodeAuthHeader } from './decodeAuthHeader';
import { CheckCredentials } from './checkCredentials';

// how to make express work in TS
import express, { json } from 'express';
const app = express();
app.use(json());

app.get('/', (_req, res) => {
  res.send('Hasura webhooks authorisation server running');
});

app.get('/webhook', (request, response) => {
  // decode the HTML header into username and (base65 decoded) password
  const decodedCredentials = decodeAuthHeader(request);

  // variables for HTTP response
  let hasuraVariables: {
    'X-Hasura-Role'?: string;
    'X-Hasura-User-Id'?: string;
    error?: string;
  };
  let responseStatus: number;

  CheckCredentials(decodedCredentials).then((result) => {
    // if we've found a matching user ID
    // and the password is correct
    if (result.exists && result.pwCorrect) {
      hasuraVariables = {
        'X-Hasura-Role': result.role || '',
        'X-Hasura-User-Id': result.userID,
      };
      responseStatus = 200;
    } else {
      // if something is wrong
      hasuraVariables = {
        // articulate what is wong (Hasura doesn't use this
        // but might be useful for front end app)
        error: !result.exists ? 'invalid username' : 'wrong password',
      };
      responseStatus = 401;
    }

    // send the response
    response.status(responseStatus).json(hasuraVariables);
  });
});

// listen for requests
// standed Express stuff
app.listen(port, () => {
  console.log('Hasura webhook authentication app listening on port ' + port);
});
