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

// Get environment values
// In development mode these will come from
// .env if the script to start is
//  node -r dotenv/config server.js
//  rather than node server.js
const port = process.env.PORT || 3000;

import { webhook } from './server/webhook';
import { changePassword } from './server/changePassword';
import { login } from './server/login';

// how to make express work in TS
import express, { json } from 'express';
const app = express();
app.use(json());

app.get('/', (_req, res) => {
  res.send('Hasura authorisation server running');
});
app.get('/webhook', webhook);
app.post('/changepassword', changePassword);
app.get('/login', login);
// listen for requests - standed Express stuff
app.listen(port, () => {
  console.log(`Tim's Hasura authentication app listening on port ${port}`);
});
