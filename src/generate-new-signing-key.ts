import { async } from 'crypto-random-string';
async({ length: 64, type: 'base64' }).then(console.log);
