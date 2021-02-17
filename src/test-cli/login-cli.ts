import { splitUsernameAndPassword } from '../tools/decodeAuthHeader';
import { generateTokens } from '../tools/jwt';
import { CheckCredentialsInDB } from '../database/dbInteraction';

splitUsernameAndPassword(process.argv[2]).then((credentials) => {
  CheckCredentialsInDB(credentials).then((result) => {
    generateTokens(result, '0.0.0.0').then(console.log);
  });
});
