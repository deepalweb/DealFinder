# DealFinder Cloudflare deployment guide

Checked against the repository on 2026-11-06. This guide distinguishes what is
already configured in source from what still needs Cloudflare account access.

## Current repository state

- `cloudflare/src/index.js` proxies requests to a Cloudflare Container running
  the combined Express API and Next.js app from the root `Dockerfile`.
- The container is configured for MongoDB, one active instance, and R2-backed
  image uploads. Its scheduled Worker ping keeps the app instance warm for the
  existing in-container notification scheduler.
- `cloudflare/wrangler.jsonc` currently has `workers_dev` enabled. The custom
  domains are commented out, so a deploy will not take over
  `dealfinderapp.lk` or `www.dealfinderapp.lk`.
- `.github/workflows/main_dealfinder.yml` still deploys `main` to Azure. Keep it
  during staging and cutover so Azure remains a rollback target.
- Mobile's default API origin is `https://dealfinderapp.lk`. It will continue
  using the current production service until that hostname is moved to the
  Cloudflare Worker (or a mobile build is explicitly configured with another
  API URL).
- This checkout has no Cloudflare login, Docker daemon, or R2 credentials in
  `backend/.env`. No Cloudflare deployment has been verified from this machine.

## Before deploying

1. Use a Cloudflare account on the Workers Paid plan; Containers require it.
2. In R2, create the `dealfinder-images` bucket and connect the public custom
   domain `images.dealfinderapp.lk` (or use an `r2.dev` URL temporarily).
3. Create an R2 S3 API token limited to that bucket with Object Read & Write.
   Keep its secret out of the repository and shell history.
4. Ensure MongoDB accepts connections from Cloudflare Containers. Prefer a
   narrowly scoped, least-privilege database user and TLS. If the MongoDB host
   only supports IP allowlists, resolve a safe connectivity approach with the
   provider before opening access broadly.
5. In Google Cloud OAuth settings, allow the staging `workers.dev` origin during
   staging and the final custom domain for production. Confirm the backend's
   `GOOGLE_CLIENT_ID` matches the client used by the web app and mobile
   `GOOGLE_WEB_CLIENT_ID`.
6. Confirm mail and Firebase credentials are available if password resets,
   Firebase account migration, or push notifications are required. These are
   optional to start the core website, but those features depend on them.

## Configure Worker secrets

The `dealfinder` Worker does not exist in this Cloudflare account yet. First
create its placeholder so Wrangler has a Worker to attach secrets to:

1. In Cloudflare Dashboard, open **Workers & Pages** → **Create application**
   → **Create Worker** → **Deploy**.
2. Name it exactly `dealfinder`; leave it on its `workers.dev` address and do
   not add a custom domain. This placeholder does not change the current site.

Cloudflare requires every name in `secrets.required` to be configured before
`wrangler deploy` succeeds. Wrangler's `secret put` command applies a secret to
an existing Worker, so create the placeholder first.

From this directory, install the lockfile-pinned tools and authenticate:

```sh
npm ci
npx wrangler login
npx wrangler whoami
```

Set required secrets interactively. Wrangler prompts for each value; do not put
secret values in command arguments or commit them to `.env` files:

```sh
npx wrangler secret put MONGO_URI
npx wrangler secret put JWT_SECRET
npx wrangler secret put JWT_REFRESH_SECRET
npx wrangler secret put R2_ACCOUNT_ID
npx wrangler secret put R2_ACCESS_KEY_ID
npx wrangler secret put R2_SECRET_ACCESS_KEY
```

For the three R2 values, use the account ID shown on R2 Overview and the
Access Key ID and Secret Access Key from the bucket-scoped S3 API token. Do not
paste either key into chat, source files, or shell command arguments.

Set optional feature secrets only when the corresponding service is configured:

```sh
npx wrangler secret put GOOGLE_CLIENT_ID
npx wrangler secret put FIREBASE_PROJECT_ID
npx wrangler secret put FIREBASE_CLIENT_EMAIL
npx wrangler secret put FIREBASE_PRIVATE_KEY
npx wrangler secret put VAPID_PUBLIC_KEY
npx wrangler secret put VAPID_PRIVATE_KEY
npx wrangler secret put M365_EMAIL
npx wrangler secret put M365_PASSWORD
```

The bucket name (`R2_BUCKET=dealfinder-images`) and public image URL
(`R2_PUBLIC_URL=https://images.dealfinderapp.lk`) are ordinary Worker variables
already set in `wrangler.jsonc`; they are not secrets. Confirm the bucket has
that exact name and its public custom domain is connected. For temporary
staging without that domain, enable the bucket's `r2.dev` URL and update
`R2_PUBLIC_URL` to that public URL in `wrangler.jsonc` before deploying. Do not
use the private S3 endpoint as `R2_PUBLIC_URL`; the app returns image URLs to
web and mobile clients.

## Stage on `workers.dev`

Keep the custom-domain `routes` disabled. Start Docker Desktop, then deploy from
this directory:

```sh
npx wrangler deploy
```

The deploy builds and publishes the container image. The first deployment can
take several minutes to provision; an available Worker URL does not necessarily
mean its container is ready. Find the assigned `workers.dev` URL in Wrangler's
output or the Cloudflare dashboard.

Check the following before cutover:

1. `GET /api/ready` returns `200` with `{"ready":true,"provider":"mongo"}`.
2. `GET /` serves the Next.js home page and can load deals.
3. Email registration and login work; verify Google sign-in separately after
   allowing the staging origin in Google OAuth settings.
4. Image upload succeeds and returns a URL under the configured
   `R2_PUBLIC_URL`.
5. Check the Worker and Container logs for repeated restarts, database errors,
   or scheduled job failures.

Use `npx wrangler tail` to follow Worker logs. Azure should continue serving
`dealfinderapp.lk` while these checks run.

### Git-based deploys

To deploy staging from GitHub, connect the existing `dealfinder` Worker under
**Workers & Pages → dealfinder → Settings → Builds → Connect**. Use the
repository and staging branch `fix/signin-sessions` (or another staging branch
you choose), root directory `cloudflare`, an empty build command, and deploy
command:

```text
npx wrangler deploy
```

Workers Builds can build the Dockerfile remotely for this project. On the
selected production branch, `npx wrangler deploy` publishes the Worker and
container image. Do not rely on the default non-production preview command:
`wrangler versions upload` uploads Worker code only and does not update the
container image. Keep the custom domain disabled during staging. After staging
passes and you are ready for cutover, coordinate the Cloudflare branch with the
existing Azure deployment workflow before switching it to `main`.

## Cut over the domain

Only cut over after the staging checks pass and R2 has all existing images.

1. Run `backend/scripts/migrateImagesToR2.js` without `--apply` to inspect the
   migration plan. Review it, then run with `--apply` during the change window.
   Run the report again afterward to catch images uploaded during the move.
2. Add `dealfinderapp.lk` to Cloudflare and complete the registrar nameserver
   change so the zone is active in Cloudflare. Preserve required mail and other
   DNS records.
3. Confirm the old Azure site is healthy and keep its deployment workflow and
   data intact for rollback.
4. Uncomment the two custom-domain entries in `wrangler.jsonc` and deploy with
   `npx wrangler deploy`. Cloudflare Custom Domains create/manage their DNS
   records; remove conflicting records if Cloudflare reports a conflict.
5. Verify `https://dealfinderapp.lk/api/ready`, the home page, login, image
   delivery, and a current mobile app build.
6. Once verified, set Workers Builds to deploy `main` with `npx wrangler deploy`.
   Coordinate this with the existing GitHub Actions workflow, which still
   deploys `main` to Azure. Keep Azure available through the rollback window.
7. Retire Azure only after DNS, mobile clients, background notifications, and
   image URLs have all been confirmed on Cloudflare.

## Rollback

If checks fail after domain cutover, disable/remove the Worker custom-domain
route, restore the previous DNS records at Cloudflare, and keep Azure running.
Do not delete the R2 bucket, Azure Storage, MongoDB data, or Azure App Service
as part of a rollback.

## Cost and scaling notes

Containers are available on Workers Paid. Current configuration limits the app
to one `basic` instance because notification scheduling still runs inside the
container; increasing instances before moving those jobs to a single scheduler
can duplicate notifications. Monitor memory and container restarts before
changing `instance_type` or `max_instances`.
