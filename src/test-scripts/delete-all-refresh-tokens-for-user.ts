import {
  DeleteAllTokensOfUser,
  GetUserByIdWithoutPassword,
} from '../database/graphql';

const userID = parseInt(process.argv[2]);

console.log('searching DB for user...');
GetUserByIdWithoutPassword(userID)
  .then((user) => {
    console.log(`now deleting this ${user.username}'s tokens...`);
    return DeleteAllTokensOfUser(user.id);
  })
  .then((tokens) => {
    console.log(`the following tokens have been erased:`);
    console.log(JSON.stringify(tokens, null, 4));
  });
