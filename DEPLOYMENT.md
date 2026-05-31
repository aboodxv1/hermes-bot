# ☁️ Deploying Hermes to Google Cloud (Always Free Tier)

Step-by-step guide to deploy this bot to a free Google Cloud VM for 24/7 uptime.

**Total cost:** $0/month forever (within Always Free Tier limits).
**Setup time:** ~45 minutes (most of which is waiting for builds/downloads).

---

## 📋 Prerequisites

- A working local Hermes setup (see [README.md](README.md))
- All OAuth tokens already authorized locally (`gws-data/`, `gcloud-data/`)
- A Google account
- A credit card (for identity verification only — Always Free Tier doesn't charge)
- A Docker Hub account (free, for image distribution)

---

## 🪜 Step 1 — Sign Up for Google Cloud Free Tier

1. Go to https://cloud.google.com/free
2. Click **"Get started for free"**
3. Sign in with your Google account
4. Fill in account information (country, individual account, no tax info)
5. Add a payment method (card)
   - Google charges $1 temporarily for verification (refunded)
   - You won't be billed unless you manually upgrade
6. Land in Google Cloud Console

---

## 🪜 Step 2 — Create a Free VM

1. Navigate: **Compute Engine** → **VM instances**
2. First-time? Click **ENABLE** to activate the Compute Engine API
3. Click **CREATE INSTANCE** and configure:

| Setting | Value |
|---|---|
| **Name** | `hermes-server` |
| **Region** | `us-west1` (or us-central1 / us-east1) — **MUST be one of these for free tier** |
| **Zone** | `us-west1-a` |
| **Machine type** | `e2-micro` (2 vCPU shared, 1 GB memory) — labeled "FREE TIER ELIGIBLE" |
| **Boot disk** | **Standard persistent disk**, 30 GB, **Ubuntu 22.04 LTS** |
| **Firewall** | Leave both HTTP/HTTPS UNCHECKED (bot uses outbound only) |

Click **CREATE**. The VM will provision in ~30 seconds.

**Important:** The price estimator will show ~$7/month — **ignore it**. The Always Free Tier credit zeroes this out as long as you stay within free limits.

---

## 🪜 Step 3 — SSH Into the VM

In the VM instances list, click the **SSH** button next to `hermes-server`. A browser-based terminal opens.

---

## 🪜 Step 4 — Install Docker on the VM

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
exit
```

Reopen SSH (click SSH again) and verify:

```bash
docker --version
docker ps
```

---

## 🪜 Step 5 — Add Swap Space (Critical for e2-micro)

The e2-micro has only 1 GB RAM. Without swap, the Hermes container may be OOM-killed under load:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

Verify the last command shows `Swap: 2.0Gi`.

---

## 🪜 Step 6 — Pull the Prebuilt Image from Docker Hub

Skip the slow in-VM build by pulling the prebuilt image:

```bash
docker pull aboodxv1/hermes-stack:latest
docker tag aboodxv1/hermes-stack:latest hermes-stack:full
docker images
```

You should see `hermes-stack:full` listed. **Pull takes ~3-5 minutes.**

### Alternative: build the image yourself

If you forked this repo and modified the Dockerfile:

```bash
git clone https://github.com/<your-username>/hermes-bot.git
cd hermes-bot
docker build -t hermes-stack:full .   # ~30-45 minutes on e2-micro
```

---

## 🪜 Step 7 — Transfer Your OAuth Tokens & Config

Your Gmail OAuth tokens (from local setup) need to be transferred to the VM.

### 7a — Create a tarball of secrets locally

On your **local machine** (where you already ran OAuth setup):

```bash
cd ~/hermes-stack
tar -czf hermes-secrets.tar.gz \
  hermes-data/.env \
  hermes-data/config.yaml \
  hermes-data/auth.json \
  gws-data \
  gcloud-data
```

Move it somewhere accessible (e.g., for Windows + WSL):
```bash
cp hermes-secrets.tar.gz /mnt/c/Users/<you>/Downloads/
```

### 7b — Upload to the VM

In the Google Cloud SSH window, click the **⚙️ gear icon** at top-right → **Upload file** → select `hermes-secrets.tar.gz`.

The file is small (~200 KB) and uploads in seconds.

### 7c — Extract on the VM

```bash
mkdir -p ~/hermes-bot && cd ~/hermes-bot
tar -xzf ~/hermes-secrets.tar.gz
rm ~/hermes-secrets.tar.gz
ls hermes-data/ gws-data/ gcloud-data/
```

Verify you see `.env`, `config.yaml`, OAuth files, etc.

---

## 🪜 Step 8 — Run the Bot

```bash
cd ~/hermes-bot
docker run -d \
  --name hermes \
  --restart unless-stopped \
  -v $(pwd)/hermes-data:/root/.hermes \
  -v $(pwd)/gws-data:/root/.config/gws \
  -v $(pwd)/gcloud-data:/root/.config/gcloud \
  hermes-stack:full
```

Verify it's running:

```bash
docker ps
docker logs --tail 30 hermes
```

---

## 🪜 Step 9 — Stop Any Local Instance

If you were running the bot locally on the same Telegram token, **stop it now** to avoid polling conflicts:

```bash
# On your local machine:
docker stop hermes && docker rm hermes
```

Telegram allows only one process per bot token. Wait ~30 seconds after stopping the local container before testing.

---

## 🪜 Step 10 — Test on Telegram

Send your bot:
```
/new
hey from the cloud
```

If it responds → **You're live 24/7 on Google Cloud.** 🎉

For an end-to-end test (proves Gmail OAuth + LLM + cloud all work):
```
send a test email to <your-email> with subject "Cloud Test" and body "Hello from GCP"
```

Check your Gmail inbox for the delivered message.

---

## 🛠️ Daily Management Commands

SSH into the VM, then:

```bash
docker ps                       # is bot running?
docker logs -f hermes           # live logs
docker restart hermes           # restart
docker stop hermes              # stop
docker start hermes             # start
docker exec -it hermes bash     # shell into container
```

To update the bot after a code change:
1. Build new image locally
2. `docker push aboodxv1/hermes-stack:latest`
3. On VM: `docker pull aboodxv1/hermes-stack:latest && docker restart hermes`

---

## 💰 Cost Safety

The deployment runs at **$0/month** as long as you stay within Always Free Tier limits:

| Resource | Free Limit | This Deployment |
|---|---|---|
| **VM instance** | 1 × e2-micro | ✅ 1 e2-micro |
| **Region** | us-west1 / us-central1 / us-east1 only | ✅ us-west1 |
| **Disk type** | Standard persistent disk only | ✅ Standard |
| **Disk size** | Up to 30 GB | ✅ 30 GB |
| **Outbound traffic** | 1 GB/month | ✅ ~50 MB/month |

### Recommended: Set a Budget Alert

1. Cloud Console → **Billing** → **Budgets & alerts**
2. **CREATE BUDGET** → name `safety-net` → amount `$1`
3. Alert thresholds: 50%, 90%, 100%

You'll receive an email if anything costs even $0.50 — a true safety net.

---

## 🆘 Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Build OOM-killed | 1 GB RAM not enough | Add swap (Step 5) or use prebuilt image |
| Telegram conflict error | Local bot still polling | `docker stop hermes && docker rm hermes` on local |
| OAuth token expired | gws tokens have TTL | `docker exec -it hermes bash` → `gws auth login -s gmail` |
| Bot is slow | e2-micro CPU throttled + geographic distance | Upgrade to e2-small (~$13/mo) or move to closer region |
| Container won't start | Missing env vars | `docker logs hermes` to see error |
| `docker ps` empty | Container crashed | `docker ps -a` to see exit code, then `docker logs hermes` |

---

## 🚀 Production Hardening (Optional)

For a more robust setup beyond the free tier:

1. **Move to a closer region** (e.g., `me-central1` Doha for MENA users) — sub-100ms latency
2. **Upgrade to e2-small** — 2 GB RAM, no CPU throttling (~$13/month)
3. **Use Docker Compose** — for more complex stacks or multi-container deployments
4. **Set up monitoring** — Google Cloud Logging is free for low volumes
5. **Automate updates** — GitHub Actions → push to Docker Hub → webhook to VM
