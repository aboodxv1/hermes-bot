# Hermes — AI Email Assistant on Telegram

A containerized AI agent that turns informal Telegram messages into professional emails. Just say *"email my professor about being late"* and the bot drafts it with an LLM, asks for approval, then sends it via your authenticated Gmail — a 5-minute writing task in 30 seconds.

**🌐 Deployed 24/7 on Google Cloud Platform** — runs continuously regardless of local machine state.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=flat&logo=google-cloud&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Telegram](https://img.shields.io/badge/Telegram-2CA5E0?style=flat&logo=telegram&logoColor=white)
![Gmail](https://img.shields.io/badge/Gmail-D14836?style=flat&logo=gmail&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![OpenAI](https://img.shields.io/badge/OpenAI_GPT--OSS-412991?style=flat&logo=openai&logoColor=white)

## ✨ Features

- 💬 **Natural conversation** — chat with the bot like a person, no rigid commands
- 🧠 **LLM-powered drafting** — rewrites rough notes into polished, professional emails
- ✏️ **Iterative refinement** — say *"make it shorter"* or *"more formal"* to revise
- ✅ **Approval workflow** — always confirms before sending
- 📧 **Real Gmail integration** — sends through your authenticated Gmail account via OAuth 2.0
- 🔒 **Private by default** — only responds to your authorized Telegram user ID
- 🐳 **Containerized** — runs anywhere Docker runs; auto-restarts on crash or reboot
- ☁️ **Cloud-deployed** — runs 24/7 on Google Cloud Free Tier; no local dependency

## 🏗️ Architecture

```
[ Telegram User ]
       │
       ▼
[ Telegram Bot API ]
       │
       ▼
┌────────────────────────────────────────────────┐
│  Google Cloud Compute Engine (us-west1)         │
│  Ubuntu 22.04 LTS │ e2-micro │ Always Free      │
│  ┌──────────────────────────────────────────┐  │
│  │  Docker Container (Ubuntu 24.04)         │  │
│  │  ┌──────────────────────────────────┐   │  │
│  │  │  Hermes Agent (Nous Research)    │   │  │
│  │  │  ├─ Intent classification         │   │  │
│  │  │  ├─ LLM orchestration              │   │  │
│  │  │  ├─ Skills system                  │   │  │
│  │  │  └─ Session memory                 │   │  │
│  │  └──────────────────────────────────┘   │  │
│  │  ┌────────────┐    ┌────────────┐       │  │
│  │  │ gws CLI    │    │ gcloud SDK │       │  │
│  │  │ (Gmail)    │    │ (OAuth 2.0)│       │  │
│  │  └────────────┘    └────────────┘       │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
       │                       │
       ▼                       ▼
[ OpenRouter / GPT-OSS ]   [ Gmail API ]
```

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **Cloud** | Google Cloud Platform (Compute Engine, Always Free Tier) |
| **Distribution** | Docker Hub (`aboodxv1/hermes-stack:latest`) |
| **Container** | Docker, Ubuntu 24.04 |
| **AI Agent** | Hermes Agent by Nous Research |
| **LLM** | OpenAI gpt-oss-120b via OpenRouter |
| **Messaging** | Telegram Bot API |
| **Email** | Gmail API via Google Workspace CLI (`gws`) |
| **Auth** | Google OAuth 2.0 via `gcloud` SDK |
| **Runtime** | Python 3, bash, tini |

## ☁️ Live Deployment

This bot is currently running on a **Google Cloud Free Tier** e2-micro VM:

- **Region:** us-west1 (Oregon)
- **Machine type:** e2-micro (2 vCPU shared, 1 GB RAM, 30 GB disk)
- **Cost:** $0/month (Always Free)
- **Auto-restart:** Container restarts on crash or VM reboot via `--restart unless-stopped`
- **Image source:** Pulled from Docker Hub on each deployment

For deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## 🚀 Quick Start (Local Development)

### Prerequisites
- Docker Desktop (with WSL2 backend on Windows)
- Telegram account
- Google / Gmail account
- OpenRouter API key ([get one free](https://openrouter.ai))

### 1. Clone and build
```bash
git clone https://github.com/aboodxv1/hermes-bot.git
cd hermes-bot
mkdir -p hermes-data gws-data gcloud-data
docker build -t hermes-stack:full .
```

### 2. Configure credentials
```bash
cp .env.example hermes-data/.env
cp config.yaml.example hermes-data/config.yaml
# Edit hermes-data/.env with your real keys
nano hermes-data/.env
```

### 3. One-time OAuth setup
```bash
docker run --rm -it \
  -v $(pwd)/hermes-data:/root/.hermes \
  -v $(pwd)/gws-data:/root/.config/gws \
  -v $(pwd)/gcloud-data:/root/.config/gcloud \
  -p 33909:33909 \
  hermes-stack:full bash
```

Inside the container:
```bash
gcloud init --no-launch-browser   # authenticate Google Cloud
gws auth setup                     # configure Workspace OAuth
gws auth login -s gmail            # authorize Gmail access
exit
```

### 4. Run as a service
```bash
docker run -d \
  --name hermes \
  --restart unless-stopped \
  -v $(pwd)/hermes-data:/root/.hermes \
  -v $(pwd)/gws-data:/root/.config/gws \
  -v $(pwd)/gcloud-data:/root/.config/gcloud \
  hermes-stack:full
```

### 5. Talk to your bot on Telegram
Find your bot, send `/start`, then say things like:
- *"email john@example.com about being late tomorrow"*
- *"send a thank you to hr@company.com for the interview"*

## 🌐 Deploy to Cloud

Skip the local build entirely — pull the prebuilt image directly:

```bash
docker pull aboodxv1/hermes-stack:latest
```

Full step-by-step Google Cloud deployment guide: see [DEPLOYMENT.md](DEPLOYMENT.md).

## 📂 Project Structure

```
hermes-bot/
├── Dockerfile               # Ubuntu 24.04 + gcloud + gws + Hermes
├── .env.example             # Template for secrets
├── config.yaml.example      # Template for agent config
├── .gitignore               # Excludes secrets and runtime data
├── DEPLOYMENT.md            # Google Cloud deployment guide
└── README.md
```

At runtime, three additional folders are mounted as volumes (gitignored):
- `hermes-data/` — agent config, conversation memory, `.env`
- `gws-data/` — encrypted Gmail OAuth tokens
- `gcloud-data/` — Google Cloud authentication state

## 🔐 Security

- Bot responds **only** to the Telegram user ID listed in `TELEGRAM_ALLOWED_USERS`
- Secrets live in `.env` and are git-ignored
- Container runs OAuth-authenticated Gmail access — no passwords stored
- Built-in security scanner (Tirith) reviews and prompts for approval on shell commands
- VM secured by Google Cloud's default firewall (no inbound ports needed; bot uses outbound long-polling)

## 🛣️ Roadmap

- [x] Local Docker deployment
- [x] Image published to Docker Hub
- [x] Source published to GitHub
- [x] 24/7 cloud deployment on Google Cloud
- [ ] Migrate to closer region (lower latency for MENA region)
- [ ] Add calendar integration (check schedule, create events)
- [ ] Add contact memory (save nicknames → emails)
- [ ] Voice message support
- [ ] Multi-language email drafting

## 🧠 What I Learned

- **Docker container OAuth flows** — handling Google's loopback redirect URI from inside a container is non-trivial (host networking, port publishing, redirect URI registration in GCP Console)
- **Agent skill systems** — Hermes ships with hundreds of skills; learned how the agent selects between similar capabilities (e.g., explicitly disabling `himalaya` so it picks `gws` for email)
- **LLM provider routing** — free-tier models on OpenRouter are heavily congested; learned to switch providers (Groq, DeepSeek) and configure fallbacks
- **WSL2 + Docker Desktop networking** — the localhost forwarding model and its quirks during OAuth flows
- **Docker image distribution** — pushing to Docker Hub for fast pull-based deployments instead of slow tarball uploads (50x faster transfers)
- **Google Cloud Free Tier deployment** — VM provisioning, SSH key management, swap configuration for memory-constrained instances (e2-micro has only 1 GB RAM)
- **Production constraints** — e2-micro CPU throttling, latency tradeoffs between regions, and when to optimize vs. accept tradeoffs

## 📜 License

MIT
