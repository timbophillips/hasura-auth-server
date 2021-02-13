import gql from 'graphql-tag';
import { ApolloClient } from 'apollo-client';
import { createHttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';
import fetch from 'cross-fetch';

export type User = {
  id: number;
  username: string;
  password: string;
  role: string;
  __typename: string;
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
        }
      }
    `,
    variables: { username: username },
  });
  return result.data['users'][0] as User;
}

export async function ChangePassword(
  userID: number,
  newPassword: string
): Promise<User> {
  const result = await client.mutate({
    mutation: gql`
      mutation ChangePassword($user_id: Int, $new_password: String) {
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
      new_password: newPassword,
    },
  });
  return result.data.update_users.returning as User;
}
