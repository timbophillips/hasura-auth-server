import { splitUsernameAndPassword } from '../tools/DecodeAuthorHeader';
import { GenerateTokens } from "../tools/GenerateTokens";
import { CheckCredentialsInDB } from '../database/graphql-interaction';

splitUsernameAndPassword(process.argv[2]).then((credentials) => {
  CheckCredentialsInDB(credentials).then((result) => {
    GenerateTokens(result, '0.0.0.0').then(console.log);
  });
});
