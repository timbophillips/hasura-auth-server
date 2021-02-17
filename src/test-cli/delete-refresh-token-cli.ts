import { CheckRefreshToken } from '../database/dbInteraction';

CheckRefreshToken(process.argv[2]).then(console.log);
