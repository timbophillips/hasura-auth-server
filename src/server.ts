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
import { CheckCredentials, ChangePassword } from './checkCredentials';

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

  CheckCredentials(decodedCredentials).then((credentials) => {
    // if we've found a matching user ID
    // and the password is correct
    if (credentials.exists && credentials.pwCorrect) {
      hasuraVariables = {
        'X-Hasura-Role': credentials.role || '',
        'X-Hasura-User-Id': credentials.userID.toString(),
      };
      responseStatus = 200;
    } else {
      // if something is wrong
      hasuraVariables = {
        // articulate what is wong (Hasura doesn't use this
        // but might be useful for front end app)
        error: !credentials.exists ? 'invalid username' : 'wrong password',
      };
      responseStatus = 401;
    }

    // send the response
    response.status(responseStatus).json(hasuraVariables);
  });
});

app.post('/changepassword', (request, response) => {
  // this POST accepts the Auth base64 credentials
  // and a JSON payload of newpassword=xxxxx
  // then updates the user's password

  // variables for HTTP response

  CheckCredentials(decodeAuthHeader(request)).then((credentials) => {
    console.log('changing password...');
    if (credentials.exists && credentials.pwCorrect) {
      console.log('cred correct...');

      // if the credentials are correct (username and soon to be old password)
      // check if the correct JSON was sent (newpassword=xxxxx)
      // if so - do the business
      if (request.body['newpassword']) {
        console.log('JSON valid...');
        ChangePassword(credentials.userID, request.body['newpassword']).then(
          (user) => {
            console.log(
              `promise has returned with user=${JSON.stringify(user, null, 4)}`
            );

            console.log(
              `promise has returned with user.id=${JSON.stringify(
                user.id,
                null,
                4
              )}`
            );
            const responseVariables = {
              'X-Hasura-Role': user.role,
              'X-Hasura-User-Id': user.id,
              'New Password': user.password,
            };
            console.log(
              `Password changed successfully, HTTP response = ${JSON.stringify(
                responseVariables,
                null,
                4
              )}`
            );

            const responseStatus = 200;
            response.status(responseStatus).json(responseVariables);
          }
        );
      } else {
        console.log('JSON invalid...');

        // the credentials were correct but the supplied JSON was not
        const responseVariables = {
          error: `correct credentials but invalid JSON payload`,
        };
        const responseStatus = 401;
        response.status(responseStatus).json(responseVariables);
      }
    } else {
      console.log('creds invalid...');

      // if something is wrong with credentials
      const responseVariables = {
        // articulate what is wong
        error: !credentials.exists
          ? 'invalid username'
          : 'wrong (old) password',
      };
      const responseStatus = 401;
      response.status(responseStatus).json(responseVariables);
    }
  });
});

// listen for requests
// standed Express stuff
app.listen(port, () => {
  console.log('Hasura webhook authentication app listening on port ' + port);
});
