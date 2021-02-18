import { CheckRefreshToken } from '../database/graphql-interaction';

CheckRefreshToken(process.argv[2]).then(console.log);
