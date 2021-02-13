import { User, GetUser, UpdatePassword } from './users';
import { Encryption } from './encryption';

const config = {
  algorithm: process.env.ALGORITHM,
  encryptionKey: process.env.ENCRYPTION_KEY,
  salt: process.env.SALT,
};

const encryptionLibrary = new Encryption(config);

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
  const encryptedPassword = encryptionLibrary.encrypt(credentials.password);
  const decryptedDBPassword = encryptionLibrary.decrypt(userFromDB.password);
  console.log(
    `supplied password = |${credentials.password}|... enrypted version = ${encryptedPassword}... DB password = |${userFromDB.password}|.... which decrypts to |${decryptedDBPassword}|`
  );
  return {
    exists: userFromDB ? true : false,
    pwCorrect: encryptedPassword == userFromDB?.password ? true : false,
    role: userFromDB?.role || '',
    userID: userFromDB ? userFromDB.id : -1,
  };
}

export async function ChangePassword(
  userID: number,
  newPassword: string
): Promise<User> {
  const encryptedNewPassword = encryptionLibrary.encrypt(newPassword);
  const updatedUserFromDB = await UpdatePassword(userID, encryptedNewPassword);
  return updatedUserFromDB;
}
