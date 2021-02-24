import express from 'express';
import atob from 'atob';

export async function DecodeAuthHeader(
  // accepts an express request
  request: express.Request
): // and then returns
// strings from the HTTP Basic authorization
// header as an object
Promise<{ username: string; nudePassword: string }> {
  // get the auth header
  const authorizationHeaderField = request.get('Authorization'); // returns undefined if it isn't there
  if (!authorizationHeaderField) {
    throw new Error('Authorization header not found');
  }
  // Split by [space] to separate <type> (eg 'Basic') from the
  // base64 encoded <credentials> which should be in username:password format
  // and decode the base64 back to ascii and stick into two strings
  console.log(`Authorization header = ${authorizationHeaderField}`);
  const [username, nudePassword] = atob(
    authorizationHeaderField.split(' ')[1] || ''
  )
    .toString()
    .split(':');
  // roll up the two strings as a neat little object
  console.log(`username ${username} in authorization header`);
  return { username: username, nudePassword: nudePassword };
}

export async function splitUsernameAndPassword(
  userPass: string
): Promise<{ username: string; nudePassword: string }> {
  const [username, nudePassword] = userPass.split(':');
  // roll up the two strings as a neat little object
  console.log(`${userPass} split into ${username} and ${nudePassword}`);
  return { username, nudePassword };
}
