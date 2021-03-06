import { CookieOptions, Request, Response } from 'express';
import { GenerateTokens } from '../tools/GenerateTokens';
import { CheckRefreshToken } from '../tools/CheckRefreshToken';
import { CheckCredentialsInDB } from '../tools/CheckCredentialsInDB';
import { DecodeAuthHeader } from '../tools/DecodeAuthorHeader';
import {
  DeleteAllTokensOfUser,
  GetUser,
  RefreshToken,
} from '../database/GraphQL';

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
      response.status(401).send(error.message);
    });
}

export function GetUserFromRefreshTokenAndThenDeleteAllTokens(
  request: Request,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
  response: Response
): void {
  let username: string;
  Promise.resolve(request.cookies['refresh-token']['token'])
    .then(CheckRefreshToken)
    .then((user) => {
      username = user.username;
      DeleteAllTokensOfUser(user.id);
    })
    .then((tokens) =>
      response.status(200).json({ tokens: tokens, username: username })
    )
    .catch((error: Error) => {
      console.error(error.stack);
      response.status(401).json({ error: error.stack });
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
      response.status(401).send(error.message);
    });
}

export function DeleteAllRefreshTokensForUser(
  request: Request,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars, no-unused-vars
  response: Response
): void {
  const username = request.params['username'];
  Promise.resolve(username)
    .then(GetUser)
    .then((user) => DeleteAllTokensOfUser(user.id))
    .then((tokens) =>
      response.status(200).json({ tokens: tokens, username: username })
    )
    .catch((error: Error) => {
      console.error(error.stack);
      response.status(401).json({ error: error.stack });
    });
}

const RespondWithTokens = (
  tokens: {
    jwt: string;
    refresh_token: RefreshToken;
    username: string;
    id: number;
    role: string;
  },
  response: Response
) => {
  response
    .cookie('refresh-token', tokens.refresh_token, cookieOptions)
    .status(200)
    .send({
      jwt: tokens.jwt,
      username: tokens.username,
      id: tokens.id,
      role: tokens.role,
    });
  console.log(
    response.headersSent
      ? 'response headers sent'
      : 'response headers not sent (?why)'
  );
  return response.headersSent;
};
