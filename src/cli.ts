import { GetAllUsers, GetUser, UpdatePassword } from './users';
import { CheckCredentials } from './checkCredentials';

// let users: Array<User> = [];

GetAllUsers().then(console.log);
// GetUsers().then(console.log);
// GetUsers().then(console.log);
// GetUsers().then(console.log);
// GetUsers().then(console.log);

GetUser('Dad').then(console.log);
// GetUser('Mum').then(console.log);
// GetUser('Molly').then(console.log);
// GetUser('Lucy').then(console.log);
// GetUser('Jessica').then(console.log);
// GetUser('Bob').then(console.log);

CheckCredentials({ username: 'Dad', password: 'password' }).then(console.log);

UpdatePassword(2, 'thisisnewIlikeIt').then(console.log);
