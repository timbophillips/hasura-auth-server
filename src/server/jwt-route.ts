import { Request, Response } from 'express';
import { generateTokens } from '../tools/jwt-functions';
import { CheckCredentialsInDB } from '../database/graphql-interaction';
import { DecodeAuthHeader } from '../tools/decoer-auth-header';

export function CheckCredentialsAndIssueTokens(
  request: Request,
  response: Response
): void {
  // decode the HTML header into username and (base65 decoded) password
  DecodeAuthHeader(request)
    .then((decodedCredentials) => CheckCredentialsInDB(decodedCredentials))
    .then((result) => generateTokens(result, request.ip))
    .then((tokens) => response.status(200).json(tokens))
    .catch((error: Error) => {
      console.error(error.message);
      response.status(401).json({ error: error.message });
    });
}
