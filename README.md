# SuperCollider Pi Experiments

Independent SuperCollider projects and experiments intended to run on Raspberry Pi hardware. They share a target platform, not a single application architecture.

## Projects

- [MLRV](MLRV/PROJECT_PLAN.md): an mlr-style live sample-cutter. Its current engine prototype is [`MLRV/mlr_engine.scd`](MLRV/mlr_engine.scd).
- [Polygnome](Polygnome/PROJECT_PLAN.md): a SuperCollider port of the monome 64 instrument for Launchpad control and external hardware-synth MIDI. Its current implementation is [`Polygnome/polygnome.scd`](Polygnome/polygnome.scd).

Each project plan tracks its goals, current state, milestones, acceptance criteria, and open questions. Keep projects independently testable; share code or utilities only when a concrete need emerges.

## Shared Tool

[`midi_probe.scd`](midi_probe.scd) helps identify MIDI messages from connected controllers. A project may also have its own copy for local testing.

## Development Notes

- The workspace uses SuperCollider 3.14.1 and the VS Code SuperCollider extension.
- Raspberry Pi compatibility is a target, not an assumption. Verify each project's audio, MIDI, controller, and performance requirements on the actual device.
- See the project plans before testing hardware; controller mappings, MIDI endpoints, and platform capabilities may still need verification.