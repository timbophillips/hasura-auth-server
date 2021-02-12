import { GetUser } from './users';
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
  userID: string;
}> {
  const userFromDB = await GetUser(credentials.username);
  const encryptedPassword = encryptionLibrary.encrypt(credentials.password);
  return {
    exists: userFromDB ? true : false,
    pwCorrect: encryptedPassword == userFromDB?.password ? true : false,
    role: userFromDB?.role || '',
    userID: userFromDB ? userFromDB.id.toString() : '',
  };
}
