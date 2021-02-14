import { decodeAuthHeader } from './decodeAuthHeader';
import { CheckCredentials } from './checkCredentials';

import { Request, Response } from 'express';

export function webhook(request: Request, response: Response): void {
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
}
