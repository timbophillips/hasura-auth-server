import { splitUsernameAndPassword } from '../tools/decodeAuthHeader';
import { generateJWT } from '../tools/jwt';
import { GetUser, CheckRefreshToken } from '../database/graphql';
import { CheckCredentialsInDB } from '../database/dbInteraction';

import btoa from 'btoa';
import { hashSync, compareSync } from 'bcryptjs';

// const nudeUsernamePassword = process.argv[2];
const { username, password } = splitUsernameAndPassword(process.argv[2]);

CheckCredentialsInDB({ username, hashPassword: password }).then((result) => {});

const hash = hashSync(password, 7);

GetUser(username)
  .then((user) => generateJWT(user, '0.0.0.0'))
  .then(console.log);

if (tokenString) {
  CheckRefreshToken(tokenString).then(console.log);
}

console.log(
  `
the nude username:password ${nudeUsernamePassword}...
splits up into username=${username}
and password=${password}
in base64 (both username:password) = ${btoa(nudeUsernamePassword)}
lets play with bcryptjs
the hash of that password (with auto salt length 7) = ${hash};
compareSync('wrong-password', hash) => ${compareSync('wrong-password', hash)}
compareSync(password, hash => ${compareSync(password, hash)}

`
);
