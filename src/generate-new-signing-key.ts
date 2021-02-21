import { async } from 'crypto-random-string';
async({ length: 32, type: 'base64' }).then(console.log);
