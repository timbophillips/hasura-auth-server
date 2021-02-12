import gql from 'graphql-tag';
import { ApolloClient } from 'apollo-client';
import fetch from 'cross-fetch';
import { createHttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';

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
