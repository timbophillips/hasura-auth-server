// import { splitUsernameAndPassword } from './tools/decodeAuthHeader';
// import { generateTokens } from './tools/jwt';
// import {
//   GetUser,
//   CheckRefreshToken,
//   UserWithoutPassword,
// } from './database/graphql';

// import btoa from 'btoa';
// import { hashSync, compareSync } from 'bcryptjs';

// const nudeUsernamePassword = process.argv[2];
// const tokenString: string | undefined = process.argv[3];
// const { username, password } = splitUsernameAndPassword(nudeUsernamePassword);

// const hash = hashSync(password, 7);

// GetUser(username)
//   .then((user) => {
//     console.log(user as UserWithoutPassword);
//     return generateTokens(user, '0.0.0.0');
//   })
//   .then(console.log);

// if (tokenString) {
//   CheckRefreshToken(tokenString).then(console.log);
// }

// console.log(
//   `
// the nude username:password ${nudeUsernamePassword}...
// splits up into username=${username}
// and password=${password}
// in base64 (both username:password) = ${btoa(nudeUsernamePassword)}
// lets play with bcryptjs
// the hash of that password (with auto salt length 7) = ${hash};
// compareSync('wrong-password', hash) => ${compareSync('wrong-password', hash)}
// compareSync(password, hash => ${compareSync(password, hash)}

// `
// );
