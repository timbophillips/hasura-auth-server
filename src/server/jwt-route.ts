import { CookieOptions, Request, Response } from 'express';
import { GenerateTokens } from '../tools/GenerateTokens';
import {
  CheckCredentialsInDB,
  CheckRefreshToken,
} from '../database/graphql-interaction';
import { DecodeAuthHeader } from '../tools/DecodeAuthorHeader';
import { RefreshToken } from '../database/graphql';

const cookieOptions: CookieOptions = {
  httpOnly: true,
  maxAge: 1000 * 60 * 60 * 24 * 30, // would expire after 1month
};

export function CheckCredentialsAndIssueTokens(
  request: Request,
  response: Response
): void {
  // decode the HTML header into username and (base65 decoded) password
  DecodeAuthHeader(request)
    .then((decodedCredentials) => CheckCredentialsInDB(decodedCredentials))
    .then((result) => GenerateTokens(result, request.ip))
    .then((tokens) => RespondWithTokens(tokens, response))
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
    .then((result) => GenerateTokens(result, request.ip))
    .then((tokens) => RespondWithTokens(tokens, response))
    .catch((error: Error) => {
      console.error(error.stack);
      response.status(401).json({ error: error.message });
    });
}

const RespondWithTokens = (
  tokens: {
    jwt: string;
    refresh_token: RefreshToken;
  },
  response: Response
) => {
  response
    .cookie('refresh-token', tokens.refresh_token, cookieOptions)
    .status(200)
    .send(tokens.jwt);
  console.log(
    response.headersSent
      ? 'response headers sent'
      : 'response headers not sent (?why)'
  );
  return response.headersSent;
};
