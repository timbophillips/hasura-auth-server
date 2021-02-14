import { splitUsernameAndPassword } from './decodeAuthHeader';
import { Encryption } from './encryption';
import btoa from 'btoa';

const config = {
  algorithm: process.env.ALGORITHM,
  encryptionKey: process.env.ENCRYPTION_KEY,
  salt: process.env.SALT,
};

const encryptionLibrary = new Encryption(config);
const nudeUsernamePassword = process.argv[2];
const { username, password } = splitUsernameAndPassword(nudeUsernamePassword);

console.log(
  `
the nude username:password ${nudeUsernamePassword}...
splits up into username=${username}
and password=${password}
in base64 (both username:password) = ${btoa(nudeUsernamePassword)}
the password in encrypted format = ${encryptionLibrary.encrypt(password)}
`
);
