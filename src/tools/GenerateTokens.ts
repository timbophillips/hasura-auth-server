import { User, RefreshToken, UserWithoutPassword } from '../database/GraphQL';
import { generateJWT, generateRefreshToken } from './TokenGenerators';

export async function GenerateTokens(
  user: User | UserWithoutPassword,
  ip: string
): Promise<{ jwt: string; refresh_token: RefreshToken }> {
  const [jwt, refreshToken] = await Promise.all([
    generateJWT(user, ip),
    generateRefreshToken(user, ip),
  ]);
  console.log(`JWT and refresh tokens generated for ${user.username}`);
  return { jwt: jwt, refresh_token: refreshToken };
}
