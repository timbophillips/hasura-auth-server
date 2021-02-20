import {
  User,
  UserWithoutPassword,
  GetUser,
  UpdatePassword,
  GetRefreshToken,
  GetUserByIdWithoutPassword,
} from './graphql';
import { hash, compareSync } from 'bcryptjs';

export async function CheckCredentialsInDB(credentials: {
  username: string;
  nudePassword: string;
}): Promise<UserWithoutPassword> {
  return GetUser(credentials.username).then((userFromDB) => {
    if (compareSync(credentials.nudePassword, userFromDB.password)) {
      console.log(
        `supplied password for ${credentials.username} matches encrypted password in database`
      );
      return RemovePasswordFromUser(userFromDB);
    } else {
      throw new Error('username found but password incorrect');
    }
  });
}

export async function UpdatePasswordInDB(
  userID: number,
  newPassword: string
): Promise<User> {
  const encryptedNewPassword = await hash(newPassword, 7);
  const updatedUserFromDB = await UpdatePassword(userID, encryptedNewPassword);
  return updatedUserFromDB;
}

function RemovePasswordFromUser(user: User): UserWithoutPassword {
  // eslint-disable-next-line no-unused-vars, @typescript-eslint/no-unused-vars
  const { password: pw, ...userWithoutPassword } = user;
  return userWithoutPassword;
}

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
  }
  const user = await GetUserByIdWithoutPassword(tokenFromDB.user);
  return user;
}
