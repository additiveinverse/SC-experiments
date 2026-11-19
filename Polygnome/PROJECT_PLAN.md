# Polygome Project Plan

## Purpose

Make a straight behavioral port of the monome 64 Polygome instrument to SuperCollider. Use the Launchpad Pro MK3 in Custom mode 7 as the grid controller and send sequenced MIDI notes to an external hardware synth. This is a standalone sequencer/controller prototype, not a synth.

The goal is to preserve Polygome's musical behavior, not recreate the Max interface.

## Reference and Port Boundary

- Original project: https://github.com/monome-community/polygome
- Target the documented 64-grid variant first: seven patterns on the top row, a hold control, loops up to eight steps, and Play, Record, Velocity, and Duration/Step modes.
- Patterns store played grid pitches, not scale intervals. Preserve the ability to change pitch mapping independently of recorded patterns.
- Build an independent implementation from documented behavior. Do not copy Max patch code or interface assets. Confirm the original project's licensing before reusing any code or assets.
- The Launchpad has no tilt sensor; tilt-dependent controls are out of scope unless replaced by an explicit mapped control.

## Current State

- `polygnome.scd` has a first controller-independent core: seven pattern slots, up to eight steps, record/play APIs, velocity and duration setters, note callbacks, and a source-filtered MIDI Clock listener with a default-BPM fallback.
- Clock handling currently estimates tempo from MIDI Clock pulses and updates a `TempoClock`; it is not yet a pulse-locked scheduler.
- Note callbacks currently log by default; there is no standalone hardware MIDI output adapter.
- No Launchpad Custom mode adapter or verified note/channel map exists yet. MIDI channel 14 is only a hypothesis.
- No runtime behavior test has been completed on the target Launchpad or a hardware synth.

## Architecture

- The sequencer owns pattern data, modes, pitch mapping, and transport behavior; the synth owns sound generation.
- Use one explicitly selected Launchpad MIDI input source and one explicitly selected synth MIDI output destination. Do not listen to or transmit through every MIDI endpoint by default.
- MIDI Clock is channel-less. Prefer clock from the configured external MIDI source; use the configured internal BPM when clock is absent. MIDI Stop is an intentional transport stop, not clock loss.
- Put MIDI endpoint IDs and device connections in `startup.scd`; do not set SuperCollider audio-server options in this project.
- Keep the note-output callback independent of the destination so hardware MIDI output is the primary adapter.

## Milestones

1. Verify the 64-grid behavior and licensing notes; inspect the Launchpad Pro MK3 Custom 7 note layout, MIDI channel, and available control buttons with `SC_/midi_probe.scd`. Treat channel 14 as unconfirmed until measured.
2. Test the core without hardware using fake note callbacks: record and play a pattern, edit velocity and duration, change loop length, play patterns polyphonically, and verify every stop/panic releases notes.
3. Add a selected-port MIDI output adapter and send a simple recorded pattern to one hardware synth. Confirm note number, output channel, velocity, duration, note-off, and panic before grid integration.
4. Add the Launchpad Custom 7 input adapter: pattern selection/trigger and hold, record input, mode selection, pitch pads, and visual feedback. Keep the pad-to-pitch map configurable.
5. Match the 64 variant's Play, Record, Velocity, and Duration/Step behavior, including adjustable loop size and patterns that can play together.
6. Add pitch setup and transposition modes (chromatic, diatonic, and arbitrary map) while preserving recorded pad pitches.
7. Implement proper MIDI Clock pulse/phase following, Start/Continue/Stop, and internal-BPM fallback. Test clock loss and reacquisition without stuck notes or abrupt pattern resets.
8. Add pattern save/load, then consider swing, probability/Gomeizer behavior, and sustain-pedal controls as later parity work.

## Acceptance

- Launchpad Custom 7 input is mapped from observed MIDI messages, with no assumed channel or note numbering.
- At least seven patterns of up to eight steps can be recorded and played with the documented modes and hold behavior.
- Patterns can sound polyphonically through a selected hardware synth; velocity and note duration are correct, and stop/panic leaves no stuck notes.
- External MIDI Clock controls the sequencer when present; the configured internal BPM is used when clock is absent, and a deliberate MIDI Stop does not trigger free-running fallback.
- The standalone project works without MLR or a SuperCollider audio server.

## Open Questions

- Which hardware synth will be the first MIDI output target, and on what MIDI channel?
- What exact note and control mapping does Launchpad Custom 7 send, and is channel 14 correct?
- Which device will provide MIDI Clock, and what default BPM should be used when it is absent?
- Does the original Polygome project have a license that permits any code or asset reuse?

## Guardrails

- No synth engine or audio-server setup in this project.
- No dependency on MLR; integrations remain optional.
- Do not assume Launchpad note mappings, MIDI channel, or clock source before probing the actual hardware.
- Keep project-level MIDI routing explicit and machine-level MIDI/audio configuration in `startup.scd`.


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