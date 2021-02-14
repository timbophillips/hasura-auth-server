import { sign, Algorithm, Secret } from 'jsonwebtoken';
import { User } from '../database/graphql';

const jwtTokenExpires = process.env.JWT_TOKEN_EXPIRES;

const hasuraGraphqlJWTSecret: { type: Algorithm; key: Secret } = JSON.parse(
  process.env.HASURA_GRAPHQL_JWT_SECRET
);

export async function genJWT(
  user: User
): Promise<{ token: string; refreshToken: string }> {
  const token = sign(
    {
      'https://hasura.io/jwt/claims': {
        'x-hasura-allowed-roles': user.roles || [],
        'x-hasura-default-role': user.role,
        'x-hasura-role': user.role,
        'x-hasura-user-id': user.id.toString(),
      },
    },
    hasuraGraphqlJWTSecret.key,
    { algorithm: hasuraGraphqlJWTSecret.type, expiresIn: `${jwtTokenExpires}m` }
  );

  // add this functionality later from https://codeforgeek.com/refresh-token-jwt-nodejs-authentication/
  const refreshToken = '';

  return { token: token, refreshToken: refreshToken };
}
