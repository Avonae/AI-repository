---
name: notify
description: Send a notification to the user's Telegram through the Apprise container on server zxc. Use whenever an instruction says to notify the user, the user asks to be pinged or told when something finishes (уведоми, напиши в телегу, пришли в телеграм, скажи когда закончишь), or a task needs a root command the user has to run.
---

# Notifications

Notifications go to the user's Telegram through the Apprise API in the `apprise` Docker container on server zxc, config key `apprise`.

## Where to run

- On zxc: run the command as is.
- On any other machine (desktop): prefix it with `ssh zxc.filinkov.org`. The host is in `~/.ssh/config`.

## Command

Pass the body on stdin with `--data-urlencode body@-`. Newlines, `&`, quotes and code blocks then survive both the shell and SSH without escaping.

```
docker exec -i apprise curl -s -X POST -d 'title=<project>' -d format=markdown --data-urlencode body@- http://localhost:8000/notify/apprise <<'EOF'
<text>
EOF
```

- `title` is the project name (for example `jobs-bot`, `ansible-playbooks`), so the user knows where the message comes from. Use `Claude Code` only outside a project.
- Always send with `format=markdown`, and format any command as code: inline `` `cmd` `` or a fenced block. Telegram shows a fenced block with a copy button.
- Success prints `Sent Telegram notification`. Anything else: tell the user the notification failed.

## Root requests

When a task needs root, the user runs the command by hand. Send the request in this shape:

- `body`: one line with what root is needed for and why, then the full command in a fenced `shell` block, starting with `sudo`.

~~~
docker exec -i apprise curl -s -X POST -d 'title=jobs-bot' -d format=markdown --data-urlencode body@- http://localhost:8000/notify/apprise <<'EOF'
Нужен root: перенести бота в /opt/jobs-bot.

```shell
sudo bash /home/ubuntu/jobs-bot-deploy.sh
```
EOF
~~~
