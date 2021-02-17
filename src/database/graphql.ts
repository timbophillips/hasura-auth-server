import gql from 'graphql-tag';
import { ApolloClient } from 'apollo-client';
import { createHttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';
import fetch from 'cross-fetch';
import { Token } from 'graphql';

export type User = {
  id: number;
  username: string;
  password: string;
  role: string;
  __typename: string;
  roles: Array<string>;
};

export type UserWithoutPassword = Omit<User, 'password'>;

export type RefreshToken = {
  ip: string;
  expires: Date;
  token: string;
  user: number;
};

const hasuraGraphQLEndpoint = process.env.HASURA_GRAPHQL_ENDPOINT;
const hasuraAdminSecret = process.env.HASURA_ADMIN_SECRET;

const httpLink = createHttpLink({
  uri: hasuraGraphQLEndpoint,
  fetch: fetch,
  headers: { 'x-hasura-admin-secret': hasuraAdminSecret },
});

const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
});

export async function GetAllUsers(): Promise<User[]> {
  const result = await client.query({
    query: gql`
      query Users {
        users {
          id
          username
          password
          role
        }
      }
    `,
  });
  return result.data['users'] as Array<User>;
}
export async function GetUser(username: string): Promise<User> {
  const result = await client.query({
    query: gql`
      query User($username: String) {
        users(where: { username: { _eq: $username } }) {
          id
          username
          password
          role
          roles
        }
      }
    `,
    variables: { username: username },
  });
  const user = result.data['users'][0] as User | undefined;
  if (user) {
    return user;
  } else {
    throw new Error('username not found in database');
  }
}
export async function GetUserWithoutPassword(
  username: string
): Promise<UserWithoutPassword> {
  const result = await client.query({
    query: gql`
      query User($username: String) {
        users(where: { username: { _eq: $username } }) {
          id
          username
          role
          roles
        }
      }
    `,
    variables: { username: username },
  });
  const userWithoutPassword = result.data['users'][0] as
    | UserWithoutPassword
    | undefined;
  if (userWithoutPassword) {
    return userWithoutPassword;
  } else {
    throw new Error('username not found in database');
  }
}
export async function UpdatePassword(
  // note that this function is agnostic
  // to the encryption and should recieve the
  // already encrypted version of the password
  userID: number,
  newHashPassword: string
): Promise<User> {
  const result = await client.mutate({
    mutation: gql`
      mutation UpdatePassword($user_id: Int, $new_password: String) {
        update_users(
          where: { id: { _eq: $user_id } }
          _set: { password: $new_password }
        ) {
          affected_rows
          returning {
            id
            username
            role
            password
          }
        }
      }
    `,
    variables: {
      user_id: userID,
      new_password: newHashPassword,
    },
  });
  return result.data.update_users.returning[0] as User;
}
export async function AddToken(token: RefreshToken): Promise<RefreshToken> {
  const result = await client.mutate({
    mutation: AddTokenGQL,
    variables: token,
  });
  return result.data.insert_refresh_tokens.returning[0] as RefreshToken;
}
export async function CheckRefreshToken(
  tokenString: string
): Promise<Token | undefined> {
  const result = await client.query({
    query: CheckRefreshTokenGQL,
    variables: { token: tokenString },
  });
  return result.data['refresh_tokens'][0] as Token | undefined;
}

const CheckRefreshTokenGQL = gql`
  query RefreshToken($token: String) {
    refresh_tokens(where: { token: { _eq: $token } }) {
      ip
      expires
      token
      user
    }
  }
`;

const AddTokenGQL = gql`
  mutation AddToken(
    $ip: String
    $expires: timestamptz
    $token: String
    $user: Int
  ) {
    insert_refresh_tokens(
      objects: [{ ip: $ip, expires: $expires, token: $token, user: $user }]
    ) {
      returning {
        ip
        expires
        token
        user
      }
    }
  }
`;

// const DeleteTokenGQL = gql`
//   mutation DeleteToken($token: String) {
//     delete_refresh_tokens(where: { token: { _eq: $token } }) {
//       affected_rows
//     }
//   }
// `;

// const DeleteAllTokensOfUserGQL = gql`
//   mutation DeleteTokensOfUSer($user: Int) {
//     delete_refresh_tokens(where: { user: { _eq: $user } }) {
//       affected_rows
//     }
//   }
// `;