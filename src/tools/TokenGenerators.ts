import { sign, Algorithm, Secret } from 'jsonwebtoken';
import { randomBytes } from 'crypto';
import {
  User,
  RefreshToken,
  AddToken,
  UserWithoutPassword,
} from '../database/GraphQL';

const jwtTokenExpiresMins = process.env.JWT_TOKEN_EXPIRES_MINS;
const refreshTokenExpiresDays = parseInt(
  process.env.REFRESH_TOKEN_EXPIRES_DAYS
);

const hasuraGraphqlJWTSecret: { type: Algorithm; key: Secret } = JSON.parse(
  process.env.HASURA_GRAPHQL_JWT_SECRET
);

export async function generateJWT(
  user: User | UserWithoutPassword,
  ip: string
): Promise<string> {
  // this bit of JS trickery
  // subs in a empty array if user.roles doesn't exist - using || []
  // adds the user.role in to the array user.roles - using concat
  // and then deletes duplicates - using [... new Set()]
  const roles = [...new Set((user.roles || []).concat(user.role))];
  // create and return the token
  return sign(
    {
      'https://hasura.io/jwt/claims': {
        'x-hasura-allowed-roles': roles,
        'x-hasura-default-role': user.role,
        'x-hasura-role': user.role,
        'x-hasura-user-id': user.id.toString(),
      },
      createdByIp: ip,
      sub: user.id.toString(),
      id: user.id.toString(),
    },
    hasuraGraphqlJWTSecret.key,
    {
      algorithm: hasuraGraphqlJWTSecret.type,
      expiresIn: `${jwtTokenExpiresMins}m`,
    }
  );
}

export async function generateRefreshToken(
  user: User | UserWithoutPassword,
  ip: string
): Promise<RefreshToken> {
  // create a refresh token that expires in x days
  const token: RefreshToken = {
    user: user.id,
    token: randomTokenString(),
    expires: new Date(
      Date.now() + refreshTokenExpiresDays * 24 * 60 * 60 * 1000
    ),
    ip: ip,
  };
  return await AddToken(token);
}

function randomTokenString() {
  return randomBytes(40).toString('hex');
}
