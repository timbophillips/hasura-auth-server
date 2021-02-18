import { splitUsernameAndPassword } from '../tools/decoer-auth-header';
import { generateTokens } from '../tools/jwt-functions';
import { CheckCredentialsInDB } from '../database/graphql-interaction';

splitUsernameAndPassword(process.argv[2]).then((credentials) => {
  CheckCredentialsInDB(credentials).then((result) => {
    generateTokens(result, '0.0.0.0').then(console.log);
  });
});
