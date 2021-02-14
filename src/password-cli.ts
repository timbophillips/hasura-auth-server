import { splitUsernameAndPassword } from './tools/decodeAuthHeader';
import btoa from 'btoa';
import { hashSync, compareSync } from 'bcryptjs';

const nudeUsernamePassword = process.argv[2];
const { username, password } = splitUsernameAndPassword(nudeUsernamePassword);

const hash = hashSync(password, 7);

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
