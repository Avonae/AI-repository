---
name: dev-workflow
description: Rules for changing code or config in a repository - numbered steps with approval for multi-part changes, subagent choice, the BA → Dev → Review cycle for projects that opt in, and commit messages. Use before editing files in any repository, before spawning agents, and before committing.
---

## Repositories

- A project is a folder with code. Every project MUST live in a GitHub repository, with the dev clone in `~/github/<repo>`.
- A project that runs on the server is deployed to `/opt/<name>`, owned by root and run as its own user without sudo. It MUST NOT run from a folder in `/home/ubuntu`.
- Docker app folders in `/opt/docker/apps` are not committed. Change them through the Ansible playbooks in `~/github/ansible-playbooks`.
- Before deleting a local copy, check it for uncommitted changes, unpushed commits and stashes.

## Workflow for multi-part changes

For work that spans several files or several distinct parts, split it into numbered steps
instead of applying everything at once:

- Before each step, state exactly which files change and what the before/after lines are.
- Wait for my approval, then apply that step, verify it (grep, lint, syntax check, test),
  and report the result.
- Only then present the next step. One step per turn — don't bundle steps together to save
  turns.

Single-file or single-purpose edits don't need this; just do them.

## Subagents

- Do not use the built-in `general-purpose` agent. For a delegated task with no better-fitting
  agent, use `avonae-agents:worker`.
- Do not pass a `model` when spawning an agent unless the task needs a different one; each
  plugin agent already pins the model that fits its role.

## Development cycle: BA → Dev → Review

The cycle applies only to projects whose `CLAUDE.md` contains the line
`Development cycle: BA → Dev → Review`. Every change in such a project MUST go through it.
A project without that line skips the cycle, with no question asked.

I am the orchestrator: I talk to the user, the agents talk only to me.

1. **BA** (`avonae-agents:ba` agent): writes a change request (CR) in `requirements/` of the repository (kept
   out of git), or where the repository `CLAUDE.md` says, and returns open questions. I ask the user, send the answers back to the same BA agent, and repeat
   until the user approves the CR. Then BA merges it into `Spec.md`.
2. **Dev** (`avonae-agents:dev` agent): implements the approved CR with tests and runs the checks.
3. **Review** (`avonae-agents:requirements-reviewer` agent): reviews the change against the CR. Findings go back to Dev;
   repeat until the verdict is APPROVE.
4. I run the app as the repository `CLAUDE.md` says, check the result, and report to the user.

- The user's approval of the CR replaces step-by-step approval from the multi-part workflow.
- A one-line fix, a text or label change, or a config tweak MAY skip BA: I state it, Dev does it,
  review still runs.
- Each repository `CLAUDE.md` MUST list its check commands and how to run the app.

## Commits

- Write commit messages with the `caveman:caveman-commit` skill by default. Invoke it
  instead of drafting the message inline.
- Invoke it for every commit, not only the first of a batch. Matching the Conventional
  Commits format by hand is not a substitute.
- Write the subject in the imperative mood.
- Add a body only for a fact the diff cannot show, such as a reason, a constraint, or a
  consequence. Never restate the changed lines.
