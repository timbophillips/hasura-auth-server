import { UserWithoutPassword, GetUser } from '../database/GraphQL';
import { compareSync } from 'bcryptjs';
import { RemovePasswordFromUser } from './RemovePasswordFromUser';

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
