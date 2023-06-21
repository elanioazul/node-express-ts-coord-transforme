declare global {
    namespace NodeJs {
        interface ProcessEnv {
            DB_SID: string;
            DB_PASSWD: string;
            DB_DOMAIN: string,
            DB_PORT: number,
            DB_BUNDLE: string;
            DB_USER: string;
            NODE_ENV: "development" | "production";
        }
    }
}
export {};