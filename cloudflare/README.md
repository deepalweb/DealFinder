# Hosting DealFinder on Cloudflare

The whole app (Express API + Next.js web app) runs as one Docker container on
**Cloudflare Containers**, behind a small Worker (`src/index.js`). Images live in **R2**.
MongoDB stays where it is (Atlas / Cosmos DB).

```
browser / mobile app ──▶ Worker (dealfinderapp.lk) ──▶ Container: Express :8080 ──▶ Next.js :3000
                                                              │
                                                              ├──▶ MongoDB
                                                              └──▶ R2 (images.dealfinderapp.lk)
```

Needs the **Workers Paid** plan ($5/month; the always-on `basic` container adds roughly $5–10/month).

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

**Secrets** (each command prompts for the value; take values from Azure → App Service → Environment variables):

```sh
npx wrangler secret put MONGO_URI
npx wrangler secret put JWT_SECRET
npx wrangler secret put JWT_REFRESH_SECRET
npx wrangler secret put FIREBASE_PROJECT_ID
npx wrangler secret put FIREBASE_CLIENT_EMAIL
npx wrangler secret put FIREBASE_PRIVATE_KEY
npx wrangler secret put VAPID_PUBLIC_KEY
npx wrangler secret put VAPID_PRIVATE_KEY
npx wrangler secret put GOOGLE_CLIENT_ID
npx wrangler secret put R2_ACCOUNT_ID
npx wrangler secret put R2_ACCESS_KEY_ID
npx wrangler secret put R2_SECRET_ACCESS_KEY
npx wrangler secret put R2_BUCKET            # dealfinder-images
npx wrangler secret put R2_PUBLIC_URL        # https://images.dealfinderapp.lk
```

Also copy these if your Azure app has them set:

- Email: `M365_EMAIL`, `M365_PASSWORD`, `EMAIL_PASSWORD`, `CONTACT_EMAIL`
- AI search: `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_MODEL`,
  `AZURE_OPENAI_API_VERSION`, `AZURE_OPENAI_RESPONSES_URL`, `AI_SEARCH_ENABLED`,
  `AI_PERSONALIZATION_ENABLED`

Every Worker secret is passed into the container as an environment variable.
Azure OpenAI is a separate Azure service: it keeps working from Cloudflare, but
don't delete it when you shut down the App Service, or AI search stops.

If MongoDB Atlas has an IP allow-list, Cloudflare's outbound IPs are not fixed:
set it to `0.0.0.0/0` (the password still protects it) before testing.

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

The `dealfinder` Worker is connected to the GitHub repo. Its build settings
(Workers → dealfinder → Settings → Build) must be:

| Setting | Value |
|---|---|
| Root directory | `cloudflare` |
| Build command | *(empty)* |
| Deploy command | `npx wrangler deploy` |
| Branch | `main` (or a feature branch while testing) |

Use `wrangler deploy`, not `wrangler versions upload`: only `deploy` updates the container.

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
