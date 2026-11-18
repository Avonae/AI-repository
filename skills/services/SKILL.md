---
name: services
description: Catalog of the self-hosted services on this server - where each one lives, how to reach it, and what the user calls it. Read it before any request that names a service or asks to look something up in one (Mealie recipes, ZenMoney finances and money questions, the recipe bot, the channels bot, n8n workflows, Trivy vulnerability scans, any Docker container), including Russian nicknames: мили, милли, рецепты, книга рецептов, бот рецептов, мили-бот, бот каналов, мониторинг каналов, нейтан, н8н, эн-эйт-эн, автоматизации, воркфлоу, уязвимости, сканер, триви, вуд, чекмейт, аптайм, эпрайз, уведомления, матрикс, обсидиан, синктинг, дзенмани, финансы, деньги, расходы, траты, доходы, бюджет, счета, сонарр, проулар, сир, покет айди, трафик, туннель, даунлоадер, докер, контейнеры, сервер, на сервере, zxc.
---

# Services catalog

Read the entry for the service the user names. Use the paths and access methods below; do not search the disk for them again.
If a fact here turns out wrong, fix this file in the same turn.

## Common layout

- "Сервер" / "на сервере" always means `zxc` (hostname `zxc.filinkov.org`): the machine Claude runs on. Run commands locally; no SSH needed.

- Docker apps: `/opt/docker/apps/<name>/docker-compose.yml`, one compose project per app. `docker compose ls` lists them.
- Public access: Cloudflare tunnel (`cloudflared`, token-based, hostnames set in the Cloudflare dashboard) and Traefik (`Host(...)` labels). Domain: `filinkov.org`.
- Public hostnames are often behind Cloudflare challenge or SSO (`pocketid`, `tinyauth`). From the server, use the localhost port or `docker exec`.
- Files under `/opt/docker/apps/*/data`, `trivy-scan`, `traefik/acme`, `matrix/secrets` are root-only. Root commands go to the user (see global CLAUDE.md).

## Mealie (recipes)

- Aliases: мили, милли, рецепты, книга рецептов.
- Container `mealie`, compose `/opt/docker/apps/mealie/`, data `/opt/docker/apps/mealie/data` (root-only).
- API: `http://127.0.0.1:9000`. Public UI: `https://eda.filinkov.org` (Cloudflare challenge: MUST NOT call it from scripts).
- API calls: use the wrapper `/opt/mealie-bot/mealie METHOD /api/path` (adds base URL and token from `/opt/mealie-bot/.env`). Example: `/opt/mealie-bot/mealie --jq '.items[].slug' GET '/api/recipes?search=борщ'`. Food search: `/opt/mealie-bot/mealie foods <words>`.
- Recipe link: `https://eda.filinkov.org/g/home/r/<slug>`.

## Mealie bot (recipe bot in Telegram)

- Aliases: бот рецептов, рецептный бот, мили-бот.
- Answers the "Рецепты" topic of a family Telegram chat; n8n receives messages and runs Claude in the bot folder.
- Dev clone: `~/github/mealie` (user ubuntu, remote `Avonae/mealie`). Edit and commit only there; read its `HANDOFF.md` before any change.
- Production: `/opt/mealie-bot` (root-owned, runs as user `mealiebot`). MUST NOT edit it by hand: the Ansible role `roles/mealie_bot` in `~/github/ansible-playbooks` (branch `dev`) deploys it.
- Deploy: push to `main` in `~/github/mealie`, set `mealie_bot_version` to the new commit SHA in `roles/mealie_bot/defaults/main/main.yml`, then run the role with a playbook on `zxc.filinkov.org` (real runs need the user's permission each time).
- Rules for the bot: `CLAUDE.md`, state: `HANDOFF.md`, n8n workflow export: `n8n/workflow.json`, `n8n/live.json`.
- Media from Telegram: `/opt/docker/apps/n8n/files/mealie` (cron deletes files older than 7 days).
- Helpers: `video` and `profile` call the `downloader` container (`127.0.0.1:8000`).

## Channels bot (Telegram channel monitor)

- Aliases: бот каналов, мониторинг каналов, channel monitor.
- Lives in n8n: workflow "Channel monitor", id `chMonitorHourly01`, hourly. Related workflows: "Sites monitor" `sitesMonitor01`, "Pages monitor" `T9nMS7HJHFLiA0PK`, "Companies monitor" `companiesMon01`, "Feed monitor" `DvEBjcMuievBWpXL`.
- Repo: `~/github/telegram-bot-checking`, remote `Avonae/telegram-bot-checking` (workflow exports in `n8n/`, extractor in `extract/`, state and next steps in `HANDOFF.md`). Read `HANDOFF.md` before any change.
- Production: `/opt/jobs-bot` (root-owned), runs as user `jobsbot` over SSH: chat `run.sh`, "Extract" `extract/run.sh`. Deploy steps: `HANDOFF.md`, section "Deployment".
- Data files: `/opt/docker/apps/n8n/files/channels-monitor/` (`channels.csv`, `state.json`, `filter.json`, `searches.json`, `pages.csv`, `boards.csv`, `sites-state.json`).
- Reads channels through the `telegram-api-server` container. Sends matches to bot @Automaaaate_bot, chat 50021989.
- Names, messages and notes for this bot MUST stay neutral (no words that reveal the topic).

## n8n (automation)

- Aliases: нейтан, эн-эйт-эн, н8н, автоматизации, воркфлоу.
- Containers `n8n`, `n8n-runner`, `postgres`; compose `/opt/docker/apps/n8n/`. Public: `n8n.filinkov.org`.
- Shared files for workflows: `/opt/docker/apps/n8n/files/` (mounted into the container).
- List workflows: `docker exec n8n n8n list:workflow`. Export: `docker exec n8n n8n export:workflow --id=<id>`.
- `n8n execute` does not work (collides with the running instance on port 5679). Test via a temporary webhook copy; see `~/github/telegram-bot-checking/HANDOFF.md`, section "Testing".
- Execution data: table `execution_data`, container `postgres`, database `n8n`, user `n8ndatabaseuser`.
- Webhooks from the host: resolve the `n8n` container IP (see `/usr/local/sbin/trivy-scan`).

## Vulnerability tracking (Trivy)

- Aliases: уязвимости, сканер, сканер уязвимостей, триви, security alerts.
- systemd `trivy-scan.timer` daily at 04:30 Asia/Tbilisi, runs `trivy-scan.service` → `/usr/local/sbin/trivy-scan`.
- Scans the image of every running container (HIGH, CRITICAL, fixed only), posts findings to the n8n webhook `security-alerts`.
- Telegram alerts (node "Alert filter") go out only for images reachable without Cloudflare Access (cloudflared, traefik, synapse, MAS, lk-jwt, syncthing, n8n: CRITICAL or KEV/EPSS) and for images that parse untrusted content (downloader, telegram-api-server, flaresolverr: KEV/EPSS only). All other images are still stored in the tables but never alert.
- Exposure: almost every `*.filinkov.org` host is behind Cloudflare Access (Google login, country rule). Without Access: `m.filinkov.org` (Synapse) and `mas.filinkov.org`. Host ports: SSH 23080, Syncthing 53131.
- App dir `/opt/docker/apps/trivy-scan` (root-only; reports in `out/reports`, payload `out/payload.json`).
- n8n side: workflows "Security alerts" `secAlertsFlow0001` and "Security alerts tables" `secAlertsTables01`.
- Host OS check: "Security alerts" runs daily at 12:00 Tbilisi over SSH as user `secscan`. Its key has a forced command (`pro security-status --format json; /usr/local/bin/reboot-cves`), so the command set in n8n is ignored. `reboot-cves` (role `security-scan` in `~/github/ansible-playbooks`) lists the CVEs fixed by packages waiting for a reboot, with their Ubuntu priority. n8n sends the reboot alert only for high/critical/unrated CVEs or a kernel update.
- Status: `systemctl status trivy-scan.service`, `journalctl -u trivy-scan.service`. Manual run needs root.

## ZenMoney (finances)

- Aliases: дзенмани, финансы, деньги, расходы, траты, доходы, бюджет, счета, транзакции.
- Any question about money, spending, income, budgets or accounts MUST start with the `zenmoney-web` container.
- Container `zenmoney-web`, public UI `fin.filinkov.org`. Updated by `zenmoney-web-update.timer`.

## Other Docker containers

| Container (compose) | What it is | Access | Aliases |
|---|---|---|---|
| `wud` | What's Up Docker: image update checks | wud.filinkov.org | вуд, обновления контейнеров |
| `checkmate`, `checkmate-mongodb`, `checkmate-capture` | Uptime monitoring | mon.filinkov.org, 127.0.0.1:52345 | чекмейт, мониторинг, аптайм |
| `apprise` | Notifications to Telegram (skill `avonae-agents:notify`) | apprise.filinkov.org | эпрайз, уведомления |
| `telegram-api-server` | TelegramApiServer (MTProto user API) for n8n | internal :9503 | телеграм апи |
| `downloader` | Local video/media downloader for the recipe bot | 127.0.0.1:8000 | даунлоадер, качалка |
| `matrix` project: `matrix`, `matrix-mas`, `matrix-postgres`, `matrix-lk-jwt`, `matrix-element` | Matrix Synapse, auth service, Element web | m.filinkov.org, mas.filinkov.org | матрикс, элемент |
| `element-admin` | Matrix admin UI | element-admin.filinkov.org | админка матрикса |
| `obsidian` | Obsidian in a browser | obs.filinkov.org | обсидиан, заметки |
| `syncthing` | File sync | sync.filinkov.org, port 53131 | синктинг |
| `free-games-claimer` | Claims free games (Epic etc.) | egs.filinkov.org | бесплатные игры |
| `sonarr` | TV series manager | sonarr.filinkov.org | сонарр, сериалы |
| `prowlarr` | Indexer manager | prowlarr.filinkov.org | проулар, индексеры |
| `seerr` | Media requests | seer.filinkov.org | сир, запросы фильмов |
| `flaresolverr` | Cloudflare challenge solver for indexers | internal :8191 | |
| `pocketid` | OIDC / passkey SSO | pid.filinkov.org, 127.0.0.1:1411 | покет айди, SSO |
| `tinyauth` | Auth proxy in front of apps | tinyauth.filinkov.org | тайни-аус |
| `traefik` | Reverse proxy | traefik.filinkov.org | трафик |
| `cloudflared` | Cloudflare tunnel | none | туннель |
| `docker-socket-proxy` | Restricted Docker API for other containers | internal :2375 | |
| `dynacat` | Dashboard (config `~/dynacat.yml`) | internal :8080 | дашборд |
| `videos` | Angie static server for videos | internal :80 | |

Jellyfin: systemd `jellyfin.service` (`/opt/jellyfin`) is inactive since 2026-11-11, but a `jellyfin` container runs and serves `jf.filinkov.org`. Folders without a running container in `/opt/docker/apps`: `FlareSolverr`, `docker-3proxy`, `homarr`, `homepage`, `uptime-kuma-api`.
