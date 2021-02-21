import { User, UpdatePassword } from '../database/GraphQL';
import { hash, genSalt } from 'bcryptjs';

export async function UpdatePasswordInDB(
  userID: number,
  newPassword: string
): Promise<User> {
  const salt = await genSalt();
  const encryptedNewPassword = await hash(newPassword, salt);
  const updatedUserFromDB = await UpdatePassword(userID, encryptedNewPassword);
  return updatedUserFromDB;
}
