import { generateTokens } from '../tools/jwt';
import {
  CheckRefreshToken,
  GetUserByIdWithoutPassword,
} from '../database/graphql';

CheckRefreshToken(process.argv[2]).then((token) => {
  GetUserByIdWithoutPassword(token.user).then((user) => {
    generateTokens(user, '0.0.0.0').then(console.log);
  });
});
