import { DecodeAuthHeader } from '../tools/decodeAuthHeader';
import { CheckCredentialsInDB } from '../database/dbInteraction';

import { Request, Response } from 'express';

export function Webhook(request: Request, response: Response): void {
  // decode the HTML header into username and (base65 decoded) password
  DecodeAuthHeader(request).then((decodedCredentials) => {
    CheckCredentialsInDB(decodedCredentials)
      .then((result) => {
        const hasuraVariables = {
          'X-Hasura-Role': result.role || '',
          'X-Hasura-User-Id': result.userID.toString(),
        };
        response.status(200).json(hasuraVariables);
      })
      .catch((error: Error) => {
        console.log(error);
        response.status(401).json({ error: error.message });
      });
  });
}
