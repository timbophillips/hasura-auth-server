import { Request, Response } from 'express';
import { generateTokens } from '../tools/jwt';
import { CheckCredentialsInDB } from '../database/dbInteraction';
import { DecodeAuthHeader } from '../tools/decodeAuthHeader';

export function Login(request: Request, response: Response): void {
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
