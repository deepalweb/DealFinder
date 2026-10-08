import { Container, getContainer } from '@cloudflare/containers';

// Runs the root Dockerfile (Express API + Next.js) — the same app Azure App Service ran.
export class DealFinderApp extends Container {
  defaultPort = 8080;
  sleepAfter = '2h'; // the cron trigger below pings every 5 min, so in practice it stays up

  constructor(ctx, env) {
    super(ctx, env);
    // Every Worker secret/var (MONGO_URI, JWT_SECRET, R2_*, ...) becomes a container env var.
    const vars = Object.entries(env).filter(([, value]) => typeof value === 'string');
    this.envVars = {
      ...Object.fromEntries(vars),
      NODE_ENV: 'production',
      IMAGE_STORAGE_PROVIDER: 'r2',
      BACKEND_URL: 'http://127.0.0.1:8080', // Next.js server-side calls stay inside the container
    };
  }
}

// ponytail: a single named instance, like the single Azure app today. node-cron jobs run
// inside it, so more instances would send every notification twice. Move the jobs to Worker
// cron triggers before raising max_instances.
const app = (env) => getContainer(env.APP, 'main');

export default {
  async fetch(request, env) {
    const headers = new Headers(request.headers);
    // Overwrite, never append: the client must not be able to choose its own IP for rate limiting.
    headers.set('X-Forwarded-For', request.headers.get('CF-Connecting-IP') || '');
    headers.set('X-Forwarded-Proto', 'https');
    return app(env).fetch(new Request(request, { headers }));
  },

  // Keeps the container awake so the scheduled notification jobs keep running,
  // and restarts it if Cloudflare ever moved or stopped it.
  async scheduled(_event, env) {
    await app(env).fetch('http://container/api/status');
  },
};
