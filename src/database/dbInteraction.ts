import { User, UserWithoutPassword, GetUser, UpdatePassword } from './graphql';
import { hashSync, compareSync } from 'bcryptjs';

export async function CheckCredentialsInDB(credentials: {
  username: string;
  nudePassword: string;
}): Promise<UserWithoutPassword> {
  return GetUser(credentials.username).then((userFromDB) => {
    if (compareSync(credentials.nudePassword, userFromDB.password)) {
      delete userFromDB.password;
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
  const encryptedNewPassword = hashSync(newPassword, 7);
  const updatedUserFromDB = await UpdatePassword(userID, encryptedNewPassword);
  return updatedUserFromDB;
}

function RemovePasswordFromUser(user: User): UserWithoutPassword {
  // eslint-disable-next-line no-unused-vars, @typescript-eslint/no-unused-vars
  const { password: pw, ...userWithoutPassword } = user;
  return userWithoutPassword;
}
