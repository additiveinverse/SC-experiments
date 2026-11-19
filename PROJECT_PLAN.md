# SC Projects: Project Plan

## Purpose

This file is the index and coordination plan for independent SuperCollider projects intended to run on Raspberry Pi hardware. The projects share a target platform, not a single application architecture. Detailed goals, milestones, acceptance criteria, and open questions live with each project:

- [SC_/MLRV project plan](SC_/MLRV/PROJECT_PLAN.md): SuperCollider mlr-style live sample-cutter.
- [Polygome project plan](SC_/Polygnome/PROJECT_PLAN.md): standalone SuperCollider port for Launchpad control and external hardware-synth MIDI.

The `SC_` folder holds all SuperCollider projects, and `OSC_` identifies the OSC control interface. Keep MLR and Polygnome as separate applications. Share ideas or utilities only when a real need appears.

## Project Folders

- `SC_/MLRV/` contains the MLR engine, MIDI probe, and project plan.
- `SC_/midi_probe.scd` is a shared MIDI probe copy at the SuperCollider folder level.
- SuperCollider 3.14.1 and the VS Code SuperCollider extension are installed. Use VS Code for this workspace; do not run the SuperCollider IDE at the same time.

## Suggested Order

1. Continue MLR locally: test the loader and cuts, then validate the Launchpad Pro MK3 mapping.
4. Verify external MIDI Clock following and fallback on MLR; MLR must retime active loops as tempo changes.
5. Try Polygnome independently with the Launchpad and a hardware synth.
6. Define the OSC contract between SuperCollider and TouchOSC, then build the controls against it.
7. Add full-load testing and headless startup only after the instrument and controls are stable.

## Cross-Project Questions

- Which project folder should own shared utilities if a real cross-project need emerges?

## Global Guardrails

- Verify each project's audio, MIDI, controller, and performance requirements on the target Raspberry Pi before claiming hardware support.
- Do not assume the iRig works on Linux or that full multi-voice capacity is available until measured on the target hardware.
- Add Quarks or UGen packs only when selected after the first stable audio milestone.
- Keep sample content licensed for the intended use.


## Project log

Newest first. One entry per working session: what happened, what was decided, what is next.

### 2026-11-06: Log added
- Each project plan under SC_ now has a log like this one.

## Research References

The following resources may inform implementation patterns but are not required runtime dependencies:

- Polygome (behavioral reference): https://github.com/monome-community/polygome
- Grid Studies for SuperCollider: https://monome.org/docs/grid/studies/sc/
- Grid Studies SuperCollider Repository: https://github.com/monome/grid-studies-sc
- MonomeSC: https://github.com/monome/MonomeSC

Grid Studies should be reviewed when designing grid interaction models, state management, LED feedback strategies, and controller abstraction layers. The project remains a behavioral port of Polygome rather than a direct adaptation of Grid Studies examples.


## Foundational Influences

The interaction design of Book II is informed by the monome ecosystem, including Grid Studies, MLR, MLRV, Polygome, and related work by Brian Crabtree and Ezra Buchla (tehn). These projects are referenced as examples of alternative approaches to performance, sequencing, and grid-based interaction rather than as direct implementation targets.