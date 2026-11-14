# DealFinder Cloudflare deployment guide

## Current deployment

- Worker: `dealfinder`
- App URLs: `https://dealfinderapp.lk` and `https://www.dealfinderapp.lk`
- Staging URL: `https://dealfinder.drtechservicelk.workers.dev`
- Container: root `Dockerfile`, one `basic` instance
- Database: MongoDB
- Image bucket: `dealfinder-assets`
- Image URL setting: public `r2.dev` URL in `wrangler.jsonc`

The app and `/api/ready` have returned HTTP 200. The R2 bucket was empty at the
last check, and an authenticated image upload still needs an end-to-end check.

## Worker secrets

Required secret names are listed in `wrangler.jsonc`. Set or rotate them
interactively from this directory:

```sh
npx wrangler secret put MONGO_URI
npx wrangler secret put JWT_SECRET
npx wrangler secret put JWT_REFRESH_SECRET
npx wrangler secret put R2_ACCOUNT_ID
npx wrangler secret put R2_ACCESS_KEY_ID
npx wrangler secret put R2_SECRET_ACCESS_KEY
```

Do not put secret values in command arguments or source files. Optional services
such as Google sign-in, Firebase notifications, and email need their own
credentials if those features are enabled.

## Image storage

The Worker sets `IMAGE_STORAGE_PROVIDER=r2` and passes its R2 credentials into
the container. `R2_BUCKET`, `R2_PUBLIC_URL`, and `R2_KEY_PREFIX` are ordinary
variables in `wrangler.jsonc`. New uploads use the `Deal Images/` object-key
prefix, with per-user subfolders below it.

The staging bucket's public `r2.dev` URL is enabled. For a branded image host,
connect `images.dealfinderapp.lk` to the bucket in Cloudflare R2 and set
`R2_PUBLIC_URL` to `https://images.dealfinderapp.lk`, then deploy again.

If database records still contain URLs from the previous image host, migrate
those objects and rewrite the database URLs before retiring that storage. Set
`LEGACY_IMAGE_HOST_SUFFIX` to that host's suffix and add local R2 credentials
to `backend/.env` before applying the migration:

```sh
cd backend
node scripts/migrateLegacyImagesToR2.js          # report only
node scripts/migrateLegacyImagesToR2.js --apply  # copy and rewrite
```

The tool never deletes source objects. Review its report before applying it.

## GitHub deployments

Connect the repository under **Workers & Pages → dealfinder → Settings →
Builds**. The Wrangler config and Cloudflare package are both in `cloudflare/`;
the Dockerfile and container build context are referenced relative to that
folder. Configure:

| Setting | Value |
|---|---|
| Root directory | `/cloudflare` |
| Build command | `npm ci` |
| Deploy command | `npx wrangler deploy` |
| Production branch | Choose the branch you want Cloudflare to deploy |

The root directory must point to `cloudflare/` so Wrangler finds
`wrangler.jsonc`; from the repository root, plain `npx wrangler deploy` can
fall back to static-assets detection and produce “Could not detect a directory
containing static files.” `npm ci` installs the locked Wrangler and
`@cloudflare/containers` dependencies before deployment. Confirm the
production branch and last deployment in the Cloudflare dashboard after
saving these settings.

## Operations

- Check health at `/api/ready` and `/api/status`.
- Follow Worker logs with `npx wrangler tail`.
- Keep `max_instances` at one while notification jobs run inside the container.
- Monitor container memory, CPU, storage, request, and network usage in Cloudflare.
