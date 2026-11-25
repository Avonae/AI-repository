---
name: dev-workflow
description: "Rules for working in the user's repositories: where repositories live and deploy, the Grill → OpenSpec → Dev → Review cycle for projects that opt in, and commit messages. Use before changing code or config in a repository, before committing, and whenever a project's CLAUDE.md contains 'Development cycle: Grill → Dev → Review' (or 'BA → Dev → Review'), even if the user does not name the skill."
---

## Repositories

- A project is a folder with code. Every project lives in a GitHub repository, so nothing is lost when a machine dies. The dev clone is `~/Sync/github/<repo>` on the desktop and `~/github/<repo>` on server zxc.
- A project that runs on the server is deployed to `/opt/<name>`, owned by root and run as its own user without sudo. It MUST NOT run from a folder in `/home/ubuntu`: a bug in the app would then reach the user's files and keys.
- Docker app folders in `/opt/docker/apps` are not committed. Change them through the Ansible playbooks in the `ansible-playbooks` repository, so the server can be rebuilt from git.
- Before deleting a local copy, check it for uncommitted changes, unpushed commits and stashes.

## Development cycle: Grill → OpenSpec → Dev → Review

The cycle applies only to projects whose `CLAUDE.md` contains the line
`Development cycle: Grill → Dev → Review` (or the older `Development cycle: BA → Dev → Review`).
Every change in such a project MUST go through it. A project without that line skips the cycle,
with no question asked.

You are the orchestrator: you talk to the user, the agents talk only to you.

Requirements live in OpenSpec (`openspec/` in the repository): current behavior in
`openspec/specs/`, each change in `openspec/changes/<name>/`. A project without `openspec/` gets
`openspec init --tools claude --scope global` first.

1. **Grill**: run the `grill-me` skill with the user on the request until every branch of the
   decision tree is resolved. Answer the questions the code can answer yourself.
2. **Propose**: run the `openspec-propose` skill with the decisions. It writes the change:
   `proposal.md`, delta specs, `design.md`, `tasks.md`. `openspec validate <name>` MUST pass. The
   user approves the change. Later edits to the plan go through `openspec-update-change`.
3. **Dev** (`avonae-agents:dev` agent): implements the tasks of the approved change with tests,
   ticks them in `tasks.md`, and runs the checks.
4. **Review** (`avonae-agents:requirements-reviewer` agent): reviews the code against the change's
   delta specs. Findings go back to Dev; repeat until the verdict is APPROVE.
5. Run the app as the repository `CLAUDE.md` says, check the result, and report to the user.
6. **Archive**: after the user accepts the result, run the `openspec-archive-change` skill. It
   merges the delta specs into `openspec/specs/`.

- The user's approval of the change replaces step-by-step approval of multi-part changes.
- A one-line fix, a text or label change, or a config tweak MAY skip grill and propose: state
  it, Dev does it, review still runs.
- Each repository `CLAUDE.md` MUST list its check commands and how to run the app, because
  Dev, Review and step 5 all depend on them.

## Commits

- On every machine, commits are authored as `Avonae <127596994+Avonae@users.noreply.github.com>`
  (global git config), so the real email never reaches GitHub. Any other author, such as
  `Ubuntu <ubuntu@zxc.filinkov.org>`, means the config was lost or overridden: fix it before
  committing.
- Write every commit message with the `caveman:caveman-commit` skill. Invoke it for each
  commit, not only the first of a batch: matching the Conventional Commits format by hand
  drifts from it.
- Write the subject in the imperative mood.
- Add a body only for a fact the diff cannot show, such as a reason, a constraint, or a
  consequence. Never restate the changed lines.
