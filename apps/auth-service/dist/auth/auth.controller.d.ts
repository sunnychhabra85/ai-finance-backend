import { AuthService } from './auth.service';
export declare class AuthController {
    private service;
    constructor(service: AuthService);
    register(body: any): Promise<{
        access_token: string;
    }>;
    login(body: any): Promise<{
        access_token: string;
    }>;
}
