import { sign, Algorithm, Secret } from 'jsonwebtoken';
import { User } from '../database/graphql';
import { randomBytes } from 'crypto';

const jwtTokenExpiresMins = process.env.JWT_TOKEN_EXPIRES_MINS;
const refreshTokenExpiresDays = parseInt(
  process.env.REFRESH_TOKEN_EXPIRES_DAYS
);

const hasuraGraphqlJWTSecret: { type: Algorithm; key: Secret } = JSON.parse(
  process.env.HASURA_GRAPHQL_JWT_SECRET
);

export async function generateJWT(
  user: User,
  ip: string
): Promise<{ token: string; refreshToken: Record<string, unknown> }> {
  // this bit of JS trickery
  // subs in a empty array if user.roles doesn't exist - using || []
  // adds the user.role in to the array user.roles - using concat
  // and then deletes duplicates - using [... new Set()]
  const roles = [...new Set((user.roles || []).concat(user.role))];
  const token = sign(
    {
      'https://hasura.io/jwt/claims': {
        'x-hasura-allowed-roles': roles,
        'x-hasura-default-role': user.role,
        'x-hasura-role': user.role,
        'x-hasura-user-id': user.id.toString(),
      },
      createdByIp: ip,
      sub: user.id,
      id: user.id,
    },
    hasuraGraphqlJWTSecret.key,
    {
      algorithm: hasuraGraphqlJWTSecret.type,
      expiresIn: `${jwtTokenExpiresMins}m`,
    }
  );
  //    return jwt.sign({ sub: user.id, id: user.id }, config.secret, { expiresIn: '15m' });

  const refreshToken = generateRefreshToken(user, ip);

  return { token: token, refreshToken: await refreshToken };
}

export async function generateRefreshToken(
  user: User,
  ip: string
): Promise<Record<string, unknown>> {
  // create a refresh token that expires in x days
  return {
    user: user.id.toString(),
    token: randomTokenString(),
    expires: new Date(
      Date.now() + refreshTokenExpiresDays * 24 * 60 * 60 * 1000
    ).toUTCString(),
    createdByIp: ip,
  };
}

function randomTokenString() {
  return randomBytes(40).toString('hex');
}
