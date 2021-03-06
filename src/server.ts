// Get environment values
// In development mode these will come from
// .env if the script to start is
//  node -r dotenv/config server.js
//  rather than node server.js
const port = process.env.PORT || 3000;
const cookieSecret = process.env.COOKIE_SECRET || 'cookiesecret';

import { HasuraWebhook } from './server/hasura-webhook';
import { ChangePassword } from './server/change-password';
import {
  CheckCredentialsAndIssueTokens,
  CheckRefreshTokenAndIssueTokens,
  DeleteAllRefreshTokensForUser,
} from './server/jwt-route';

// how to make express work in TS
import express, { json } from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';

const app = express();
app.use(json());
app.use(cookieParser(cookieSecret));
app.use(
  cors({
    origin: true,
    exposedHeaders: ['set-cookie', 'Set-Cookie'],
    credentials: true,
  })
);

// generic message
app.get('/', (_req, res) => {
  res.send('Hasura authorisation server running');
});

// Hasura webhook server
// test by using httpie
// http -v :3000/webhook --auth jessica:2114
// or test with Hasura Graphiql console
// ... adding a Request Header
// --> key = Authorization
// --> Value = Basic amVzc2ljYToyMTE0
// (which is base64 for jessica:2114)
// and then remove the hasura-collaborator-token Header
// (which is effectively using the admin secret key)
app.get('/webhook', HasuraWebhook);

// password changing.. test with
// http --auth Dad:password POST :3000/changepassword newpassword=password2
app.post('/changepassword', ChangePassword);

// include username:password in auth header
// a JWT and a refresh token will be returned in the response
app.get('/login', CheckCredentialsAndIssueTokens);

// include refresh token in json refreshtoken=xxx
app.get('/refresh', CheckRefreshTokenAndIssueTokens);

// this route will try and work out
// who was "logged on " on the client
// based on the refreshToken in the cookie
app.get('/logout', DeleteAllRefreshTokensForUser);

// include refresh token in json refreshtoken=xxx
// and then all the user's tokens will be deleted
// (for logging out)
app.get('/logout/:username', DeleteAllRefreshTokensForUser);

// standard Express fluff
app.listen(port, () => {
  console.log(`Tim's Hasura authentication app listening on port ${port}`);
});
