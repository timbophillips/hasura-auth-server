import express from 'express';
import atob from 'atob';

export async function DecodeAuthHeader(
  // accepts an express request
  request: express.Request
): // and then returns
// strings from the HTTP Basic authorization
// header as an object
Promise<{ username: string; hashPassword: string }> {
  // get the auth header
  const authorizationHeaderField = request.get('Authorization'); // returns undefined if it isn't there
  console.log(authorizationHeaderField);
  if (!authorizationHeaderField) {
    throw new Error('Authorization header not found');
  }

  // Split by [space] to separate <type> (eg 'Basic') from the
  // base64 encoded <credentials> which should be in username:password format
  // and decode the base64 back to ascii and stick into two strings
  const [username, hashPassword] = atob(
    authorizationHeaderField.split(' ')[1] || ''
  )
    .toString()
    .split(':');
  // roll up the two strings as a neat little object
  return { username: username, hashPassword: hashPassword };
}

export function splitUsernameAndPassword(
  userPass: string
): { username: string; password: string } {
  const [username, password] = userPass.split(':');
  // roll up the two strings as a neat little object
  console.log(`${userPass} split into ${username} and ${password}`);
  return { username: username, password: password };
}
