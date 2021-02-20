import { User, UserWithoutPassword } from '../database/GraphQL';

export function RemovePasswordFromUser(user: User): UserWithoutPassword {
  // eslint-disable-next-line no-unused-vars, @typescript-eslint/no-unused-vars
  const { password: pw, ...userWithoutPassword } = user;
  return userWithoutPassword;
}
