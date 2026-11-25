---
name: services
description: "Catalog of self-hosted services on server zxc - location, access, deploy, user's names for them. Read before any request naming a service, container, *.filinkov.org host or the server. Names: server, zxc, Docker, containers, Mealie, recipe bot, channels bot, n8n, workflows, downloader, Trivy, security alerts, ZenMoney, zenmoney-web, finances, money, dashboard, Dynacat, monitoring, Checkmate, WUD, Apprise, Matrix, Obsidian, Quartz, Syncthing, Jellyfin, Sonarr, Prowlarr, Seerr, PocketID, Tinyauth, Traefik, Cloudflare tunnel; сервер, докер, контейнеры, мили, рецепты, бот рецептов, бот каналов, нейтан, н8н, автоматизации, воркфлоу, даунлоадер, уязвимости, триви, дзенмани, финансы, деньги, расходы, траты, бюджет, счета, дашборд, динакат, мониторинг, аптайм, чекмейт, вуд, эпрайз, уведомления, матрикс, обсидиан, кварц, синктинг, джеллифин, фильмы, сериалы, сонарр, проулар, сир, покет айди, трафик, туннель."
---

# Services catalog

Read the entry for the service the user names. Use the paths and access methods below; do not search the disk for them again.
If a fact here turns out wrong, fix this file in the same turn.

## Common layout

- "Сервер" / "на сервере" always means `zxc` (hostname `zxc.filinkov.org`). On zxc run commands locally; from another machine prefix them with `ssh zxc.filinkov.org`.
- Paths `~/github/<repo>` below are the server clones (user ubuntu). On the desktop the clones live in `~/Sync/github/<repo>`.

- Docker apps: `/opt/docker/apps/<name>/docker-compose.yml`, one compose project per app. `docker compose ls` lists them.
- Public access: Cloudflare tunnel (`cloudflared`, token-based, hostnames set in the Cloudflare dashboard) and Traefik (`Host(...)` labels). Domain: `filinkov.org`.
- Public hostnames are often behind Cloudflare challenge or SSO (`pocketid`, `tinyauth`). From the server, use the localhost port or `docker exec`.
- Files under `/opt/docker/apps/*/data`, `trivy-scan`, `traefik/acme`, `matrix/secrets` are root-only. Root commands go to the user through the `avonae-agents:notify` skill, section "Root requests".

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

## Downloader (media downloader)

- Aliases: даунлоадер, качалка.
- Container `downloader`, `127.0.0.1:8000` (`/info`, `/download`, `/health`): yt-dlp and gallery-dl over HTTP for the recipe bot, the channel posts bot and n8n.
- Ansible role `roles/downloader` in `~/github/ansible-playbooks` (branch `dev`); MUST NOT edit `/opt/docker/apps/downloader` by hand. Secrets (cookies, Instagram proxy) live in the gitignored `roles/downloader/vars/main.yml`.
- Instagram goes through a static ISP proxy and a dedicated account; other sites go direct.
- Details, checks, cookie refresh and proxy change: Basic Memory note `projects/downloader` in project `claude-knowledge`. Read it before any change.

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
- Deploy a workflow change without a restart: `docker cp` + `n8n import:workflow` + `n8n publish:workflow --id=<id>`, or the public API (`PUT /workflows/{id}`, then `POST /workflows/{id}/activate`; key in `~/.config/n8n-api-key`). MUST NOT `docker restart n8n` for it: that kills running executions. Older handoff notes that ask for a restart are outdated. BusyBox `wget` in the container has no PUT: use `node -e` with `fetch`.
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
| `dynacat` | Dashboard (role `roles/dynacat` in `~/github/ansible-playbooks`) | dash.filinkov.org, internal :8080 | дашборд, дэшборд, динакат |
| `quartz` | Static site from the vault folder `share/` | notes.filinkov.org | кварц, сайт заметок |
| `jellyfin` | Media server | jf.filinkov.org | джеллифин, фильмы |
| `mealie-videos` | Angie static server for recipe videos (role `roles/mealie`) | internal :80 | |

Jellyfin lives outside `/opt/docker/apps`: compose `/opt/jellyfin/compose.yaml`, started by the oneshot systemd unit `jellyfin.service` (`docker compose up -d`). Folders without a running container in `/opt/docker/apps`: `FlareSolverr`, `docker-3proxy`, `homarr`, `homepage`, `uptime-kuma-api`.

## Obsidian vault backup

- Aliases: бэкап хранилища, бэкап обсидиана, vault push.
- n8n workflow "Vault push" runs hourly. It logs in over SSH with a forced-command key and runs `/opt/obsidian-git/vault-push.sh`.
- The script commits the Syncthing vault `/opt/docker/apps/syncthing/config/obsidian_vault` as user `ubuntu` and pushes to `Avonae/Obsidian-vault` (branch `main`) with the deploy key `~/.ssh/gh_obsidian_vault`.
- Ansible role `roles/obsidian_git` in `~/github/ansible-playbooks`, playbook `obsidian_git.yml`. MUST NOT edit `/opt/obsidian-git` by hand.
