---
name: signal-desk-collector
description: Design SignalDesk collector-node topology, source adapter boundaries, spool storage, and transfer behavior. Use when working on the Raspberry Pi collector lane, raw payload contracts, or collection retries and acknowledgements.
---

# SignalDesk Collector

Read `AGENTS.md`, `docs/architecture/intelligence-platform-topology.md`, `docs/data/source-catalog.md`, and `docs/ops/pi-collector-node.md` first.

## Operate
- Keep the collector node lightweight, resilient, and always-on.
- Prefer replayable local spool writes over direct-fire-and-forget delivery.
- Separate collection success from central ingestion success.
- Treat retries, acknowledgement, and observability as first-class behavior.

## References
- Ops: `docs/ops/service-model.md`
- Coordination: `coordination/tasks.yaml`, `coordination/decision-log.md`
