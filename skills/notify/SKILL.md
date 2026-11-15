---
name: notify
description: Send a notification to the user's Telegram through the Apprise container. Use whenever an instruction says to notify the user, or the user asks for a notification.
---

# Notifications

Send notifications (delivered to Telegram) through the Apprise API in the `apprise` Docker container, config key `apprise`:

```
docker exec apprise curl -s -X POST -d 'title=Claude Code' -d 'format=markdown' -d 'body=<text>' http://localhost:8000/notify/apprise
```

- Any command in a notification MUST be formatted as code: inline `` `cmd` `` or a fenced block for multi-line commands. Always send with `format=markdown`.


## Root requests

When a task needs root, send the request in this exact shape:

- `title` MUST be the project name (for example `jobs-bot`, `ansible-playbooks`), not `Claude Code`.
- `body` MUST be one line with what root is needed for and why, then the full command in a fenced `shell` block, starting with `sudo`. Telegram shows that block with a copy button.
- Pass the body with `--data-urlencode`, so newlines and special characters survive.

~~~
docker exec apprise curl -s -X POST -d 'title=jobs-bot' -d 'format=markdown' --data-urlencode 'body=Нужен root: перенести бота в /opt/jobs-bot.

```shell
sudo bash /home/ubuntu/jobs-bot-deploy.sh
```' http://localhost:8000/notify/apprise
~~~
