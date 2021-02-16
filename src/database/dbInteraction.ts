import { User, GetUser, UpdatePassword } from './graphql';
import { hashSync, compareSync } from 'bcryptjs';

export async function CheckCredentialsInDB(credentials: {
  username: string;
  password: string;
}): Promise<{
  exists: boolean;
  pwCorrect: boolean;
  role: string;
  userID: number;
  roles?: Array<string>;
}> {
  const userFromDB = await GetUser(credentials.username);
  return {
    exists: userFromDB ? true : false,
    pwCorrect: userFromDB
      ? compareSync(credentials.password, userFromDB.password)
      : false,
    role: userFromDB?.role || '',
    userID: userFromDB ? userFromDB.id : -1,
    roles: userFromDB.roles || [userFromDB.role],
  };
}

export async function UpdatePasswordInDB(
  userID: number,
  newPassword: string
): Promise<User> {
  const encryptedNewPassword = hashSync(newPassword, 7);
  const updatedUserFromDB = await UpdatePassword(userID, encryptedNewPassword);
  return updatedUserFromDB;
}

//export async function
