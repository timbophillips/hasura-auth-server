import { DecodeAuthHeader } from '../tools/DecodeAuthorHeader';
import {
  CheckCredentialsInDB,
  UpdatePasswordInDB,
} from '../database/graphql-interaction';

import { Request, Response } from 'express';

export function ChangePassword(request: Request, response: Response): void {
  DecodeAuthHeader(request)
    .then((decodedCredentials) =>
      // check the credentials
      CheckCredentialsInDB(decodedCredentials)
    )
    .then((result) => {
      // update the password in the database
      if (!request.body['newpassword']) {
        throw new Error('newpassword field not provided in POSTed JSON');
      }
      return UpdatePasswordInDB(result.id, request.body['newpassword']);
    })
    .then((user) => {
      console.log(`password for ${user.username} successfully changed`);
      response.status(200).json({
        message: `password for ${user.username} successfully changed`,
      });
    })
    .catch((error: Error) => {
      console.error(error.stack);
      response.status(401).json({ error: error.message });
    });
}
