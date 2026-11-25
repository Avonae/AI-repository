---
name: wrap-up
description: Close out a task or session - ask the user whether the result is accepted, what is left and what to remember, then record it in Basic Memory (log entry, checkpoint or project fact). Use it whenever the user says итоги, подведи итоги, закругляемся, на сегодня всё, готово, принято, сохрани прогресс, wrap up, or otherwise signals the task is done or paused, even without naming the skill. Prefer it over bm-checkpoint at the end of a task: it decides whether a checkpoint is needed at all and calls bm-checkpoint itself.
---

# Wrap-up

Goal: the next session starts knowing what was done and what is left, and the knowledge base holds no noise.

## 1. Facts
- In a git repository: `git status --short`, unpushed commits (`git log --oneline @{u}..`), commits and check results from this session. Not a repository: skip this step.
- Use the check results already in the session. Re-running checks costs time and can change state; the user asked for a summary, not a new test run.

## 2. Questions
One AskUserQuestion call with 2-3 questions, in the user's language. One call means one interruption. Build the options from step 1 and the session, so the user picks instead of typing:
- Is the result accepted? Options: accepted / not finished / it was only questions.
- What is left? Options: uncommitted files, unpushed commits, open steps (multiSelect).
- What to remember? Options: candidate facts and decisions from the session, plus "nothing".

## 3. Write
Target: the Basic Memory project in `basicMemory.primaryProject` of the Claude settings (project `.claude/settings.json` overrides `~/.claude/settings.json`); follow that project's `README.md`. Facts in English. The knowledge base is pushed to GitHub, so secrets MUST NOT be written.
- Accepted: add an entry to `log/YYYY-MM.md` (for example `log/2026-11.md`) under `## DD-MM-YYYY · <topic>`: result, commits (short SHA), what is left. Create the file if the month has none.
- Not finished: run the `basic-memory:bm-checkpoint` skill; its next action is what is left.
- Only questions: write nothing unless the user named something to remember. Empty entries bury the useful ones.
- Each thing to remember goes to one place, so it is never duplicated:
  - a project fact or state → fix the note in `projects/` in place (`bm_read`, then `bm_edit`); git keeps the history;
  - a decision with a reason → the `basic-memory:bm-decide` skill; it writes a `type: decision` note to `decisions/`. Never put decisions in `projects/`;
  - a habit or command of this one repository → auto memory;
  - a behavior rule for all projects → propose a line for `~/.claude/CLAUDE.md` and write it only after approval, because it changes every future session.

## 4. Report
One line per written note: its path.
