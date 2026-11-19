# MLRV Project Plan

## Purpose

Build a playable SuperCollider reimplementation of the mlr live sample-cutter. This is a standalone project, separate from taktBerryPi.

## Current State

- `mlr_engine.scd` contains the first looping/cut prototype and a file/folder loader.
- Loop playback has been heard working; sample loading and quantized cuts still need explicit testing.
- `midi_probe.scd` identifies Launchpad Pro MK3 MIDI messages.
- SuperCollider 3.14.1 and the VS Code SuperCollider extension are installed. Use VS Code for this workspace; do not run the SuperCollider IDE at the same time.

## Architecture

- Launchpad Pro MK3 is the intended controller; verify its MIDI mapping and LED feedback on the actual device.
- Start with 6 lanes x 8 cut positions, leaving controls on the grid/outer buttons. Keep playback independent of this mapping.
- Keep MLR as a standalone grid sample-cutter application. Do not merge its playback engine into taktBerryPi.

## Milestones

1. Validate `mlr_engine.scd`: sample loading, repeat/tempo fit, immediate cuts, quantized cuts, and lane replacement/cleanup.
2. Follow MIDI Beat Clock from the configured source and fall back to the configured BPM on clock loss; update quantized cuts and active lane playback rates when tempo changes.
3. Add robust folder/sample selection and per-lane loop-length settings; handle missing files and mono/stereo formats deliberately.
4. Connect the Launchpad Pro MK3: confirm note/CC map, choose an 8x8 layout, add LED/playhead feedback, and provide panic/stop controls.
5. Add MLR behaviors in order: groups/choke, mute/levels, pattern record/playback, then live input capture.
6. Profile CPU and test long playback and repeated sample changes.

## Acceptance

Six lanes can load and play samples; pad presses cut to the expected position at the chosen quantization; LEDs reflect playback; panic stops all sound; no stale buffers or stuck notes remain after replacement.

## Open Questions

- Which sample files and loop lengths should be used for testing?
- Which Launchpad Pro MK3 mode and MIDI ports appear when connected?

## Guardrails

- Keep MLR independent of the taktBerryPi voice-module project.
- Keep sample content licensed for the intended use.
- Machine-level audio and MIDI settings (output device, channel counts, sample rate, MIDI connections) belong in `startup.scd`, not in project files. A project file that assigns `s.options.*` silently overrides the machine's settings, and a `nil` assignment resets them to the default. Before adding any such line to a project file, state what it overrides, what happens on a machine that lacks it, and how it was verified; prefer reading the setting and warning over assigning it.
- MIDI Clock source selection and MIDI endpoint connections also belong in `startup.scd`; the engine should register only a listener for the explicitly selected source.

## Grid Interaction Research (MLRV / Polygome / SuperCollider)

Investigate grid-based performance paradigms as a potential interaction layer for Book II. Particular focus should be placed on MLRV-style sample manipulation and Polygome-inspired grid pattern workflows. Development of any grid-based subsystem should be informed by the SuperCollider Grid Studies project and monomeSC architecture.  

## Project log

Newest first. One entry per working session: what happened, what was decided, what is next.

### 2026-11-06: Log added
- Start of the log; earlier history is in git and the sections above.

## Research References

The following resources may inform implementation patterns but are not required runtime dependencies:

- Polygome (behavioral reference): https://github.com/monome-community/polygome
- Grid Studies for SuperCollider: https://monome.org/docs/grid/studies/sc/
- Grid Studies SuperCollider Repository: https://github.com/monome/grid-studies-sc
- MonomeSC: https://github.com/monome/MonomeSC

Grid Studies should be reviewed when designing grid interaction models, state management, LED feedback strategies, and controller abstraction layers. The project remains a behavioral port of Polygome rather than a direct adaptation of Grid Studies examples.


## Foundational Influences

The interaction design of Book II is informed by the monome ecosystem, including Grid Studies, MLR, MLRV, Polygome, and related work by Brian Crabtree and Ezra Buchla (tehn). These projects are referenced as examples of alternative approaches to performance, sequencing, and grid-based interaction rather than as direct implementation targets.