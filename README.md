# signal-desk

SignalDesk is a personal Android-first investment intelligence app for keyword, sector, and theme monitoring.

## Automation
- Supervisor docs: `docs/ops/automation-supervisor.md`
- One-shot doctor check: `powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\run-supervisor.ps1 doctor`
- One dry cycle: `powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\run-supervisor.ps1 once -DryRun`
- Continuous loop: `powershell -ExecutionPolicy Bypass -File .\scripts\orchestrator\run-supervisor.ps1 loop -Interval 60`
