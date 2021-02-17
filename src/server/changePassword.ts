import { decodeAuthHeader } from '../tools/decodeAuthHeader';
import {
  CheckCredentialsInDB,
  UpdatePasswordInDB,
} from '../database/dbInteraction';

import { Request, Response } from 'express';

export function changePassword(request: Request, response: Response): void {
  // this POST accepts the Auth base64 credentials
  // and a JSON payload of newpassword=xxxxx
  // then updates the user's password

  // variables for HTTP response
  decodeAuthHeader(request).then((decodedCredentials) => {
    CheckCredentialsInDB(decodedCredentials).then((credentials) => {
      console.log('changing password...');
      if (credentials.exists && credentials.pwCorrect) {
        console.log('cred correct...');

        // if the credentials are correct (username and soon to be old password)
        // check if the correct JSON was sent (newpassword=xxxxx)
        // if so - do the business
        if (request.body['newpassword']) {
          console.log('JSON valid...');
          UpdatePasswordInDB(
            credentials.userID,
            request.body['newpassword']
          ).then((user) => {
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
          });
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
}
