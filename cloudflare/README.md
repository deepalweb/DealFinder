# DealFinder on Cloudflare

The website and Express API run together in one Cloudflare Container behind a
Worker. MongoDB stores application data and R2 stores uploaded images.

```text
Web and mobile clients → dealfinderapp.lk / www.dealfinderapp.lk → Worker → Container
                                                                        ├─ MongoDB
                                                                        └─ R2
```

The app domains are attached to the Worker. Staging is also available at
`https://dealfinder.drtechservicelk.workers.dev`. Image uploads currently return
the bucket's public `r2.dev` URL; `images.dealfinderapp.lk` can be used after it
is connected to the bucket and `R2_PUBLIC_URL` is updated.

## Deploy

From this directory:

```sh
npm ci
npx wrangler login
npx wrangler deploy
```

Cloudflare Workers Builds can deploy pushes from GitHub. Connect the repository
under **Workers & Pages → dealfinder → Settings → Builds**. Keep the root
directory at `/`, set the build command to `npm run cloudflare:install`, and
set the deploy command to `npm run cloudflare:deploy`. These root scripts run
Wrangler from `cloudflare/`, where its `wrangler.jsonc` configuration lives.

## Required Worker configuration

Set these secrets through Wrangler or the Cloudflare dashboard. Never commit
their values:

```text
MONGO_URI
JWT_SECRET
JWT_REFRESH_SECRET
R2_ACCOUNT_ID
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
```

`R2_BUCKET`, `R2_PUBLIC_URL`, and `R2_KEY_PREFIX` are non-secret variables in
`wrangler.jsonc`. The configured bucket is `dealfinder-assets`; new user uploads
are written under its `Deal Images/` key prefix.

## Notes

- Container disk is temporary; image uploads must use R2.
- The container is limited to one instance because its notification scheduler
  runs inside the app.
- If existing database records still point to an old image host, migrate those
  objects into R2 before retiring that host. See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md).
