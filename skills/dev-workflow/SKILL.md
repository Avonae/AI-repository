---
name: dev-workflow
description: Rules for changing code or config in a repository - numbered steps with approval for multi-part changes, subagent choice, the Grill → OpenSpec → Dev → Review cycle for projects that opt in, and commit messages. Use before editing files in any repository, before spawning agents, and before committing.
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

## Development cycle: Grill → OpenSpec → Dev → Review

The cycle applies only to projects whose `CLAUDE.md` contains the line
`Development cycle: Grill → Dev → Review` (or the older `Development cycle: BA → Dev → Review`).
Every change in such a project MUST go through it. A project without that line skips the cycle,
with no question asked.

I am the orchestrator: I talk to the user, the agents talk only to me.

Requirements live in OpenSpec (`openspec/` in the repository): current behavior in
`openspec/specs/`, each change in `openspec/changes/<name>/`. A project without `openspec/` gets
`openspec init --tools claude --scope global` first.

1. **Grill**: I run the `grill-me` skill with the user on the request until every branch of the
   decision tree is resolved. Questions the code can answer I answer myself.
2. **Propose**: I run the `openspec-propose` skill with the decisions. It writes the change:
   `proposal.md`, delta specs, `design.md`, `tasks.md`. `openspec validate <name>` MUST pass. The
   user approves the change. Later edits to the plan go through `openspec-update-change`.
3. **Dev** (`avonae-agents:dev` agent): implements the tasks of the approved change with tests,
   ticks them in `tasks.md`, and runs the checks.
4. **Review** (`avonae-agents:requirements-reviewer` agent): reviews the code against the change's
   delta specs. Findings go back to Dev; repeat until the verdict is APPROVE.
5. I run the app as the repository `CLAUDE.md` says, check the result, and report to the user.
6. **Archive**: after the user accepts the result, I run the `openspec-archive-change` skill. It
   merges the delta specs into `openspec/specs/`.

- The user's approval of the change replaces step-by-step approval from the multi-part workflow.
- A one-line fix, a text or label change, or a config tweak MAY skip grill and propose: I state
  it, Dev does it, review still runs.
- Each repository `CLAUDE.md` MUST list its check commands and how to run the app.

## Commits

- Write commit messages with the `caveman:caveman-commit` skill by default. Invoke it
  instead of drafting the message inline.
- Invoke it for every commit, not only the first of a batch. Matching the Conventional
  Commits format by hand is not a substitute.
- Write the subject in the imperative mood.
- Add a body only for a fact the diff cannot show, such as a reason, a constraint, or a
  consequence. Never restate the changed lines.
