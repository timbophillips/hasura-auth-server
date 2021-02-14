import { User, GetUser, UpdatePassword } from './users';
import { hashSync, compareSync } from 'bcryptjs';

export async function CheckCredentials(credentials: {
  username: string;
  password: string;
}): Promise<{
  exists: boolean;
  pwCorrect: boolean;
  role: string;
  userID: number;
}> {
  const userFromDB = await GetUser(credentials.username);

  console.log(`hash from DB = ${userFromDB.password}`);
  console.log(`hash of password = ${hashSync(credentials.password, 7)}`);

  return {
    exists: userFromDB ? true : false,
    pwCorrect: userFromDB
      ? compareSync(credentials.password, userFromDB.password)
      : false,
    role: userFromDB?.role || '',
    userID: userFromDB ? userFromDB.id : -1,
  };
}

export async function ChangePassword(
  userID: number,
  newPassword: string
): Promise<User> {
  const encryptedNewPassword = hashSync(newPassword, 7);
  const updatedUserFromDB = await UpdatePassword(userID, encryptedNewPassword);
  return updatedUserFromDB;
}
