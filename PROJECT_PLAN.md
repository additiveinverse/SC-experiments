# SC Projects: Project Plan

## Purpose

This file is the index and coordination plan for three independently testable projects. Detailed goals, milestones, acceptance criteria, and open questions live with each project:

- [SC_/MLRV project plan](SC_/MLRV/PROJECT_PLAN.md): SuperCollider mlr-style live sample-cutter.
- [SC_/TaktBerryPi project plan](SC_/TaktBerryPi/PROJECT_PLAN.md): headless Raspberry Pi voice module.
- [OSC_taktBerryUI project plan](TouchOSC/OSC_taktBerryUI/PROJECT_PLAN.md): TouchOSC controls and local sample-browser UI.
- [Polygome project plan](SC_/Polygnome/PROJECT_PLAN.md): standalone SuperCollider port for Launchpad control and external hardware-synth MIDI; independent of TaktBerryPi and MLR.

The `SC_` folder holds all SuperCollider projects, and `OSC_` identifies the OSC control interface. Keep MLR and taktBerryPi as separate applications. Share ideas or utilities only when a real need appears.

## Project Folders

- `SC_/MLRV/` contains the MLR engine, MIDI probe, and project plan.
- `SC_/TaktBerryPi/` contains the voice-module project plan and is the home for its SuperCollider runtime.
- `SC_/midi_probe.scd` is a shared MIDI probe copy at the SuperCollider folder level.
- `TouchOSC/OSC_taktBerryUI/` contains the UI project plan and is the home for project-specific OSC controls.
- `TouchOSC/` also contains existing TouchOSC templates and experiments; only taktBerry-specific controls belong in `OSC_taktBerryUI/`.
- SuperCollider 3.14.1 and the VS Code SuperCollider extension are installed. Use VS Code for this workspace; do not run the SuperCollider IDE at the same time.

## Shared Boundaries

- MLR is the grid sample-cutter; taktBerryPi is a general-purpose MIDI sound module. Keep their applications and runtime behavior independent.
- `TouchOSC/OSC_taktBerryUI/` controls `SC_/TaktBerryPi/` but does not own audio behavior. UI or network loss must not interrupt audio safety or leave notes stuck.
- External MIDI Beat Clock is the shared timing source when present. Each standalone script listens to its configured source and falls back to its own default BPM on clock loss. MIDI Stop is an intentional transport stop, not clock loss.
- Digitakt channels 9-16 are taktBerryPi defaults, not a hardware dependency. TaktBerryPi remains a voice module; Polygnome is an independent optional prototype, not a TaktBerryPi dependency.
- Custom Digitakt firmware and Overbridge integration are out of scope; that work belongs in a separate project.

## Suggested Order

1. Continue MLR locally: test the loader and cuts, then validate the Launchpad Pro MK3 mapping.
2. Confirm taktBerryPi/audio-interface compatibility and choose its generic MIDI connection.
3. Prove taktBerryPi's single-voice audio/MIDI path and performance margin before scaling the proposed voice count.
4. Verify external MIDI Clock following and fallback on TaktBerryPi and MLR; MLR must retime active loops as tempo changes.
5. Try Polygnome independently with the Launchpad and a hardware synth; keep any TaktBerryPi routing optional and separate.
6. Define the OSC contract between `SC_/TaktBerryPi/` and `TouchOSC/OSC_taktBerryUI/`, then build the controls against it.
7. Add full-load testing and headless startup only after the instrument and controls are stable.

## Cross-Project Questions

- What is the preferred first MIDI connection for taktBerryPi: Digitakt USB MIDI, DIN MIDI interface, or another controller?
- Which project folder should own shared utilities if a real cross-project need emerges?

## Global Guardrails

- Do not assume the iRig works on Linux or that full multi-voice capacity is available until measured on the target hardware; see the taktBerryPi plan for its hardware gate.
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