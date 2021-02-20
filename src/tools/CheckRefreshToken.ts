import {
  UserWithoutPassword,
  GetRefreshToken,
  GetUserByIdWithoutPassword,
  DeleteToken,
} from '../database/GraphQL';

export async function CheckRefreshToken(
  token: string
): Promise<UserWithoutPassword> {
  const tokenFromDB = await GetRefreshToken(token);
  console.log(
    `${token} matches token from DB with user_id=${tokenFromDB.user}`
  );
  // if the token has expired then throw an error
  if (new Date(tokenFromDB.expires) < new Date(Date.now())) {
    throw new Error('token expired');
  } else {
    console.log(`token is still valid on time criteria`);
    await DeleteToken(token);
    console.log(`token removed from DB (can only be used once)`);
  }
  const user = await GetUserByIdWithoutPassword(tokenFromDB.user);
  return user;
}
