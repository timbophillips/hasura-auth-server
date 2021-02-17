import { DecodeAuthHeader } from '../tools/decodeAuthHeader';
import {
  CheckCredentialsInDB,
  UpdatePasswordInDB,
} from '../database/dbInteraction';

import { Request, Response } from 'express';

export function ChangePassword(request: Request, response: Response): void {
  if (request.body['newpassword']) {
    // decode the HTML header into username and (base65 decoded) password
    DecodeAuthHeader(request)
      .then((decodedCredentials) => {
        // check the credentials
        CheckCredentialsInDB(decodedCredentials)
          .then((result) => {
            // update the password in the database
            UpdatePasswordInDB(result.id, request.body['newpassword']).then(
              (user) => {
                console.log(
                  `password for ${user.username} successfully changed`
                );
                response.status(200).json({
                  message: `password for ${user.username} successfully changed`,
                });
              }
            );
          })
          .catch((error: Error) => {
            console.error(error.message);
            response.status(401).json({ error: error.message });
          });
      })
      .catch((error: Error) => {
        console.error(error.message);
        response.status(401).json({ error: error.message });
      });
  } else {
    console.error('newpassword header not found in posted HTTP');
    response
      .status(401)
      .json({ error: 'newpassword header not found in posted HTTP' });
  }
}
