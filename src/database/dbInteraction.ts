import { User, GetUser, UpdatePassword } from './graphql';
import { hashSync, compareSync } from 'bcryptjs';

export async function CheckCredentialsInDB(credentials: {
  username: string;
  hashPassword: string;
}): Promise<{
  exists: boolean;
  pwCorrect: boolean;
  role: string;
  userID: number;
  roles?: Array<string>;
}> {
  return GetUser(credentials.username).then((userFromDB) => {
    if (compareSync(credentials.hashPassword, userFromDB.password)) {
      return {
        exists: userFromDB ? true : false,
        pwCorrect: true,
        role: userFromDB?.role || '',
        userID: userFromDB ? userFromDB.id : -1,
        roles: userFromDB.roles || [userFromDB.role],
      };
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

// export async function CheckOldPasswordAndUpdateWithNewInDB(
//   username: string,
//   hashPassword: string,
//   newPassword: string
// ): Promise<User> {
//   CheckCredentialsInDB({ username, hashPassword }).then((credentials) => {
//     const encryptedNewPassword = hashSync(newPassword, 7);
//     const updatedUserFromDB = await UpdatePassword(
//       credentials.userID,
//       encryptedNewPassword
//     );
//   });
//   return updatedUserFromDB;
// }

//export async function
