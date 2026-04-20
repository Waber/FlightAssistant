# Working agreements
- Always assume that author is a newbie and needs explanation of proposed/implemented solution, code
- As author is a newbie in mobile development, have in mind that you might need to propse a tool or IDE for author to handle your work
- Give the answer in language you were asked (mainly polish or english) but in code always use english and standard documentation that corresponds to principles of clean code
- Store notes of each step done in the project, like a journal with date of implementing or last edit of solution, keep it tidy and assume that other developer or model might be using it
- Document Ai model used for each step (Name like Claude Code or ChatGPT Codex and precise version)
- For each next task delivered after 2026-04-19, add time tracking in `docs/development-journal.md`:
  - total task duration,
  - if team/subagents are used: team total duration and per-member duration (Planner, Developer, Tester, and main coordinator if applicable).
- For each reprioritization request, add a short status split in the journal:
  - what is already implemented,
  - what remains for the next iteration backlog.
- If a task is executed without subagents, include coordinator-only time as total task duration.

## Agents handling
- For each task that requires some in depth analysis spawn a team of agents with:
  - Analytics/PM: this one is responsible for documenting tasks (also in journal), preparing tickets, instruction and evaluation of how the functionality should look and be handled by end user
  - Engineer: Gets tickets/instructions from Analytics and implements it, he is a experienced mobile developer, with knowledge about full SDLC and database technologies, he also fixes bugs reported by QA
  - QA: does the manual testing and automation testing from unit till E2E, reports to coordinator and Analytic/PM, cooperates with Developer
  - Occasionally if needed you may spawn also a infrastructure engineer which handles devops topics, database and similar ones.
