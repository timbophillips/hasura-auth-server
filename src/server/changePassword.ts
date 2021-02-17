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
        CheckCredentialsInDB(decodedCredentials)
          .then((result) => {
            UpdatePasswordInDB(result.userID, request.body['newpassword']).then(
              (user) => {
                response.status(200).json({
                  message: `password for ${user.username} successfully changed`,
                });
              }
            );
          })
          .catch((error: Error) => {
            console.log(error);
            response.status(401).json({ error: error.message });
          });
      })
      .catch((error: Error) => {
        console.log(error);
        response.status(401).json({ error: error.message });
      });
  }
}
