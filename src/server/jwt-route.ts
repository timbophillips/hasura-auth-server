import { Request, Response } from 'express';
// eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
import { JSONCookies } from 'cookie-parser';

import { generateTokens } from '../tools/jwt-functions';
import {
  CheckCredentialsInDB,
  CheckRefreshToken,
} from '../database/graphql-interaction';
import { DecodeAuthHeader } from '../tools/decoer-auth-header';

export function CheckCredentialsAndIssueTokens(
  request: Request,
  response: Response
): void {
  // decode the HTML header into username and (base65 decoded) password
  DecodeAuthHeader(request)
    .then((decodedCredentials) => CheckCredentialsInDB(decodedCredentials))
    .then((result) => generateTokens(result, request.ip))
    .then((tokens) => {
      response
        .cookie('refresh-token', tokens.refresh_token, {
          httpOnly: true,
          maxAge: 1000 * 60 * 60 * 24 * 30, // would expire after 1month
        })
        .status(200)
        .send(tokens.jwt);
    })
    .catch((error: Error) => {
      console.error(error.stack);
      response.status(401).json({ error: error.message });
    });
}

export function CheckRefreshTokenAndIssueTokens(
  request: Request,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
  response: Response
): void {
  Promise.resolve(request.cookies['refresh-token']['token'])
    .then(CheckRefreshToken)
    .then((tokens) => {
      response
        .cookie('refresh-token', tokens.refresh_token, {
          httpOnly: true,
          maxAge: 1000 * 60 * 60 * 24 * 30, // would expire after 1month
        })
        .status(200)
        .send(tokens.jwt);
      return tokens.refresh_token;
    })
    .catch((error: Error) => {
      console.error(error.stack);
      response.status(401).json({ error: error.message });
    });
}
