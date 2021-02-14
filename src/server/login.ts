import { Request, Response } from 'express';

export function login(request: Request, response: Response): void {
  console.log(
    JSON.stringify(request, null, 4) + JSON.stringify(response, null, 4)
  );
}
