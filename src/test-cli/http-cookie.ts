import { readFileSync, writeFileSync } from 'fs';
const raw = readFileSync('./session.json');
const session = JSON.parse(raw.toString());
console.log(JSON.stringify(session, null, 4));
session['headers'] = { Cookie: JSON.stringify(session['cookies']) };
console.log(JSON.stringify(session, null, 4));
writeFileSync('session-cookie.json', JSON.stringify(session));
