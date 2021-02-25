import { DecodeAuthHeader } from '../tools/DecodeAuthorHeader';
import { CheckCredentialsInDB } from '../tools/CheckCredentialsInDB';
import { Request, Response } from 'express';

export function HasuraWebhook(request: Request, response: Response): void {
  // decode the HTML header into username and (base65 decoded) password
  DecodeAuthHeader(request)
    .then((decodedCredentials) => CheckCredentialsInDB(decodedCredentials))
    .then((result) => {
      response.status(200).json({
        'X-Hasura-Role': result.role || '',
        'X-Hasura-User-Id': result.id.toString(),
      });
    })
    .catch((error: Error) => {
      console.error(error.message);
      response.status(401).send(error.message);
    });
}
