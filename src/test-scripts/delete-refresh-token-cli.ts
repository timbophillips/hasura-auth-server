import { DeleteToken, GetRefreshToken } from '../database/graphql';

const tokenString = process.argv[2];

console.log('searching DB for token...');
GetRefreshToken(tokenString)
  .then((refreshToken) => {
    console.log(refreshToken);
    console.log('now deleting token...');
    return DeleteToken(refreshToken.token);
  })
  .then((refreshToken) => {
    console.log(refreshToken);
    console.log('now searching for it again');
    return GetRefreshToken(refreshToken.token);
  })
  .then(console.log);
