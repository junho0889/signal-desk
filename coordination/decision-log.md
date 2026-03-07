# Decision Log

## 2026-03-08

### DEC-001
- Decision: start the project in `E:\source\signal-desk`
- Reason: clean repo boundary, easy session onboarding, clear separation from unrelated work

### DEC-002
- Decision: use a file-based coordination model instead of relying on direct worker chat
- Reason: Codex sessions do not share durable memory, so repo documents are the stable communication layer

### DEC-003
- Decision: use `SignalDesk` as the working product name
- Reason: neutral, reusable, and aligned with a dashboard that explains signals rather than promising returns

### DEC-004
- Decision: run backend services with a local Docker stack and PostgreSQL
- Reason: low operational overhead, repeatable local deployment, and clear service boundaries during early development

### DEC-005
- Decision: use least-privilege PostgreSQL roles for app, migration, and readonly access
- Reason: application code should never rely on superuser access and security assumptions must be visible to every worker

### DEC-006
- Decision: use one orchestrator session plus up to three worker sessions for true parallel work
- Reason: this keeps coordination overhead manageable while still allowing real concurrency

### DEC-007
- Decision: use git worktrees instead of separate full clones for local multi-worker execution
- Reason: worktrees reduce disk usage, keep object history shared, and isolate each worker branch safely

### DEC-008
- Decision: require explicit QA review before project completion or release sign-off
- Reason: defects and integration drift should be caught by a dedicated worker rather than assumed away
