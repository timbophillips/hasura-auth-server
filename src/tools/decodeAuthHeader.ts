import express from 'express';
import atob from 'atob';

export function decodeAuthHeader(
  // accepts an express request
  request: express.Request
): // and then returns
// strings from the HTTP Basic authorization
// header as an object
{ username: string; password: string } {
  // minor JS Array ninja to get the auth header
  // Split by [space] to separate <type> (eg 'Basic') from the
  // base64 encoded <credentials> which should be in username:password format
  // and decode the base64 back to ascii and stick into two strings
  const [username, password] = atob(
    request.get('Authorization')?.split(' ')[1] || ''
  )
    .toString()
    .split(':');
  // roll up the two strings as a neat little object
  return { username: username, password: password };
}

export function splitUsernameAndPassword(
  userPass: string
): { username: string; password: string } {
  const [username, password] = userPass.split(':');
  // roll up the two strings as a neat little object
  console.log(`${userPass} split into ${username} and ${password}`);
  return { username: username, password: password };
}
