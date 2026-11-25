---
name: notes
description: Rules for personal notes and instructions written for the user in the Obsidian vault - language, wording, headings, and where to save. Use whenever you write a note, an instruction, a how-to or a cheat sheet for the user to read later, or the user says заметка, запиши, сохрани в обсидиан, инструкция, шпаргалка, even if they do not name the skill. Not for blog drafts, Basic Memory session notes, or repository docs.
---

## Personal notes

The user reads these notes later as a cheat sheet while doing the task, so every line must help them act.

- Write the note in the language the user writes in, like chat replies. In such notes:
  - Keep them short.
  - In Russian, use «должен» / «не должен» / «следует» instead of MUST / MUST NOT / SHOULD. English keywords break the flow of a Russian text.
  - Title headings with a noun phrase («Установка плагина»), not an imperative («Установи плагин»).
  - An instruction note contains only the steps. Do not describe how the result behaves afterwards: the user sees that when they get there.
  - Drop any sentence that neither tells the user what to do nor gives a fact they need (e.g. «Без них в шаге 4 нечего будет включать»).

## Where to save

Save notes to `claude-knowledge/notes/` in the Obsidian vault unless the user names another folder:

- Desktop (Linux and macOS): `~/Sync/Obsidian-vault/claude-knowledge/notes/`
- Server zxc: `/opt/docker/apps/syncthing/config/obsidian_vault/claude-knowledge/notes/`

`Блог/` in the vault is for blog drafts only.
