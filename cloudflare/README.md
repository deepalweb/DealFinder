# Hosting DealFinder on Cloudflare

For the deployment readiness status, staging steps, cutover checklist, and
rollback procedure, see [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md).

The whole app (Express API + Next.js web app) runs as one Docker container on
**Cloudflare Containers**, behind a small Worker (`src/index.js`). Images live in **R2**.
MongoDB stays where it is (Atlas / Cosmos DB).

```
browser / mobile app ──▶ Worker (dealfinderapp.lk) ──▶ Container: Express :8080 ──▶ Next.js :3000
                                                              │
                                                              ├──▶ MongoDB
                                                              └──▶ R2 (images.dealfinderapp.lk)
```

Requires the **Workers Paid** plan. Container and egress charges depend on actual
usage and instance sizing; check Cloudflare's [current Containers pricing](https://developers.cloudflare.com/containers/platform/pricing/)
before enabling production traffic.

## 1. One-time setup

All commands run from this `cloudflare/` folder.

```sh
npm ci
npx wrangler login
```

**R2 bucket for images**

1. Dashboard → R2 → Create bucket `dealfinder-images`.
2. Bucket → Settings → Custom Domains → connect `images.dealfinderapp.lk`
   (or enable the `r2.dev` URL for testing). That URL is `R2_PUBLIC_URL`.
3. R2 → Manage API tokens → create a token with **Object Read & Write** on that bucket.
   Note the Access Key ID, Secret Access Key and your Account ID.

Follow [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#configure-worker-secrets) to
create the initial `dealfinder` Worker, then enter required secrets through
Wrangler's prompts. The bucket name and public URL are already configured as
non-secret Worker variables; do not use `wrangler secret put` for them.

Optional features such as Firebase push, Google sign-in, email, and Azure AI
need their corresponding secrets configured too. Azure OpenAI is a separate
Azure service; it keeps working from Cloudflare, but do not delete it when you
shut down the App Service if AI search still depends on it.

Do not widen a MongoDB IP allow-list to `0.0.0.0/0` just to make staging work.
Use the database provider's supported Cloudflare connectivity option or review
the access change with the database owner first.

## 2. Deploy and test (Azure keeps serving users)

Push to the build branch (see "Automatic deploys" below), or deploy from your machine:

Start Docker Desktop, then:

```sh
npx wrangler deploy
```

The app comes up at `https://dealfinder.<your-subdomain>.workers.dev`. The first
request after a deploy takes ~30s while the container starts. Check:

- `/api/status` responds
- the home page loads deals, login works
- upload an image as a merchant: its URL should start with `R2_PUBLIC_URL`

Logs: `npx wrangler tail`, or Dashboard → Workers → dealfinder → Logs.

## 3. Cutover

1. **Copy images** (from `backend/`, with the Azure + R2 values in `backend/.env`):
   ```sh
   node scripts/migrateImagesToR2.js          # report only
   node scripts/migrateImagesToR2.js --apply  # copy blobs, rewrite URLs in MongoDB
   ```
   Run it right before switching DNS; run it once more after to catch late uploads.
2. **Move DNS**: add `dealfinderapp.lk` to Cloudflare (Dashboard → Add a domain) and
   change the nameservers at your `.lk` registrar. Remove the old A/CNAME records for
   `dealfinderapp.lk` and `www` that point at Azure.
3. Uncomment `routes` in `wrangler.jsonc` and run `npx wrangler deploy` again.
4. Workers → dealfinder → Settings → Build: set the branch to `main`.
   Pushes to `main` now deploy to Cloudflare. Delete `.github/workflows/main_dealfinder.yml`
   to stop deploying to Azure.

## Automatic deploys (Workers Builds)

Connect the existing `dealfinder` Worker to GitHub from
**Workers → dealfinder → Settings → Builds → Connect**. For initial staging,
use the current staging branch `fix/signin-sessions` (or another staging
branch), so pushes to `main` can continue the existing Azure deployment.
Configure these build settings:

| Setting | Value |
|---|---|
| Root directory | `cloudflare` |
| Build command | *(empty)* |
| Deploy command | `npx wrangler deploy` |
| Branch | `fix/signin-sessions` (staging) |

Leave preview deploys disabled for this Container Worker. The default preview
command uploads Worker code but does not update the container image. The
production branch's `npx wrangler deploy` builds and deploys both. Coordinate
any switch to `main` with the Azure workflow before domain cutover.

## 4. Shutting Azure down

Mobile app versions already in the Play Store / App Store call the Azure URL
(`dealfinderlk-...azurewebsites.net`) directly. New builds use `dealfinderapp.lk`.
Keep the Azure app running until most users have updated, then delete it along with
the Azure Storage account.

## Notes

- `max_instances` is 1 on purpose: the scheduled notification jobs run inside the
  app, so a second instance would send every notification twice.
- Container disk is wiped on restart, so `IMAGE_STORAGE_PROVIDER` is forced to `r2`.
- Out-of-memory restarts in the logs → change `instance_type` to `standard-1`.
