# taktBerryPi Project Plan

## Purpose

Build a headless, general-purpose Raspberry Pi voice module named taktBerryPi. The Digitakt is its first intended controller and audio destination, not a required host or firmware target.

Current status and next steps are in the latest entry of the [Project log](#project-log).

## Project log

Newest first. One entry per working session: what happened, what was decided, what is next.

### 2026-11-04: Catch-up

Status: phase one engine is written but not yet tested on the target hardware.

Done:
- Hardware gate cleared: MIDI input works in SuperCollider on the Pi, and audio plays from the Pi's stock headphone out. That output is fine for development, but take final latency, CPU, and xrun numbers from a USB interface.
- Wrote `taktberry.scd`: drum voice(s) triggered by note number on any non-synth channel, one four-note subtractive synth slot on MIDI channel 15, CC block and OSC control per drum voice, a panic function (CC 120/123 or `/taktberry/panic`), a master limiter, and a CPU/temperature report every 5 seconds.
- Scope note: the agreed slice was one drum voice, but the code was written with all six drum voices (an overshoot, not a deliberate scope change). The six voices share one `SynthDef`, so the extra voices are only table rows. They are written but untested, and there is no need to write them again; to run the strict slice, limit `~cfg.drumNotes` to one note.
- Made the decisions listed below.

Blocker found 2026-11-05: installing SuperCollider via apt on the Pi pulled in a JACK setup that conflicts with PipeWire, and the sound device stopped working unless forced to `hw:2`. Resolve this before step 2 (see Open Questions).

Next, in order:
1. Set `~cfg.drumNotes` using the note numbers from `SC_/midi_probe.scd` (one note for the strict slice, or all six since the code exists).
2. Boot `taktberry.scd` on the Pi and fix any errors.
3. Test the drum voice(s) and MIDI config: note triggers, retriggering, CC and OSC parameter control, and panic.
4. Play four synth notes together with a drum. Check overlapping chords and fast repeated notes for stuck notes.
5. Record CPU, peak CPU, temperature, and xruns.
6. Focus on the synth engine next: tune the subtractive slot, then add `DXPlay` as the second engine if the numbers allow.

Parked until after the synth engine work: shared effects, TouchOSC layout, persistence and headless boot.

Not part of this project's next steps: getting the repos onto GitHub (needed before any deploy automation) and deploying to the Pi from git or SSH.

## Architecture

- Six flexible sample-plus-synthesis drum voices and two identical, independently patched four-note synth slots.
- Digitakt channels 9-16 are defaults, not a hardware dependency. No sequencer is included in taktBerryPi.
- Use samples plus native/lightweight drum synthesis; consider selected ported UGens for resonant send processing. Clouds is an optional shared stereo effect, not one instance per drum.
- Default to SuperCollider (`sclang`/`scsynth`) headless on Raspberry Pi OS.
- Receive standard MIDI over USB or a MIDI interface; send stereo audio through a compatible audio interface. Keep MIDI mapping and audio routing device-agnostic.
- Prefer external MIDI Beat Clock from one configured MIDI source; fall back to a configured internal BPM when clock pulses time out. MIDI Start/Continue/Stop control transport; Stop must not trigger fallback playback.
- Polygnome is an independent prototype and is not required for TaktBerryPi. It may be tested with external hardware synths; any future TaktBerryPi connection remains optional.
- `TouchOSC/OSC_taktBerryUI/` controls taktBerryPi over OSC. The Pi display/encoder/buttons are a separate local sample-browser/status UI.

## Decisions

- Phase one is one drum voice plus one four-note subtractive synth slot (`SC_/TaktBerryPi/taktberry.scd`). Measure CPU, temperature, and stability before adding voices.
- The clock listener uses the source ID configured in `startup.scd`; MIDI Clock is channel-less and is independent of Launchpad's note channel.
- Drums are triggered by note number (lowest six pad notes, configurable) on any non-synth MIDI channel. Per-voice control is by CC block and OSC, so no hardware MIDI channel per drum is required.
- Engine addressing is voice-indexed: OSC addresses use `/taktberry/drum/{1-6}/{param}`. The TouchOSC UI owns the "selected voice" state; the engine holds none.
- The second synth engine is `DXPlay` from OrangeModels (https://github.com/aetbet/OrangeModels): 2-voice, 6-operator FM with 32 DX7-style presets from `syx` banks. It is installed only after the first stable audio milestone, per the guardrail below.
- Engines may differ in polyphony (DXPlay is 2-voice; the subtractive slot is 4-note), so the UI must not assume four notes per slot. Engine switching from TouchOSC is by an OSC engine selector that applies to new notes.

### Why DXPlay

- It already parses DX7 sysex presets and matches Dexed's behaviour, which core `FM7` does not. `FM7` is only a 6x6 modulation matrix with no preset support, so DX7 patches would need custom sysex parsing, algorithm tables, level curves, and envelope conversion.
- Needs the `wslib` quark (or the manual trimming alternative in `DXPlay.sc`), has no internal low-pass gate or decay envelope (apply them externally), and runs best at a 48 kHz server sample rate.
- Unverified: Raspberry Pi (ARM) build, CPU cost, and licence (no licence file seen in the repository listing; derived from Mutable Instruments firmware).

### Fallbacks if DXPlay does not pan out

- Core `FM7` with a small set of hand-made patches or a reduced Volca FM-style feature set.
- A TX81Z-style 4-operator voice: `FM7` can run four operators, but the TX81Z's extra operator waveforms would need custom oscillators.
- Other OrangeModels engines (`SMEmu` string machine, `SQArp` square-voice chords) or core-UGen engines.

## Hardware Gate

Do not make the referenced Digitakt firmware/Overbridge experiment a dependency. taktBerryPi must run independently and expose ordinary MIDI input and stereo audio output. Modified-firmware work belongs in a separate project.

Before choosing hardware:

1. Confirm Pi 4B RAM, power supply, and Raspberry Pi OS support for the selected SuperCollider build.
2. Identify the iRig model and verify that it appears as a usable Linux audio output device. If not, choose a compatible stereo USB audio interface.
3. Confirm MIDI input using the Digitakt and at least one other MIDI source, keeping channel assignments configurable.
4. Measure latency, CPU, and audio stability before increasing voice count or adding shared effects.

Pi RAM, iRig model, screen model, and physical control wiring are still unconfirmed.

## Milestones

1. ~~Confirm Pi model/RAM, power supply, audio interface, and MIDI connection. Verify the iRig on Linux or select a compatible stereo interface.~~ Done 2026-11-04: MIDI input works in SuperCollider on the Pi and audio plays from the stock headphone out. The iRig is still unverified and the headphone out is for development only.
2. Prove one MIDI-triggered drum voice and one four-note synth voice end-to-end with a generic MIDI source. Use a low output level and verify panic/recovery before musical stress testing.
3. Add remaining drum channels with sample plus native synthesis layers; add independent four-note synth slots 15 and 16 from a bounded shared engine palette.
4. Add shared tuned resonator/effect sends and optional Clouds processing only after baseline voice capacity is measured.
5. Add persistence, headless boot, watchdog/reconnect handling, CPU/temperature reporting, and a full-load soak test.

## Acceptance

Configurable MIDI channels trigger six intended drum parts and two four-note polyphonic synth slots; audio is stable through a generic stereo interface; all-sounds-off and restart recovery work; measured worst-case load has headroom. Digitakt channels 9-16 are the default mapping, and another MIDI controller can use a different mapping without changing the voice engine.

## Open Questions

- Which MIDI connection will be used first: Digitakt USB MIDI, DIN MIDI interface, or another controller?
- Which MIDI source will supply Beat Clock, and is the initial fallback BPM 120?
- Exact Pi 4B RAM and the iRig model/audio capability?
- Audio stack on the Pi: should scsynth run through PipeWire's JACK layer (`pipewire-jack`, launched with `pw-jack`), or against a dedicated JACK server on a fixed `hw:` device? Pick one, make it start automatically, and record the exact working commands here. Verify after the choice that headphone out and the USB interface both still work.
- Does OrangeModels build and run acceptably on the Pi, and what is DXPlay's CPU cost?
- Setup, not a design question: read the Launchpad and Digitakt drum note numbers with `SC_/midi_probe.scd` and put them in `~cfg.drumNotes`. The design is decided: the lowest six pad notes, configurable.

## Guardrails

- No sequencer in taktBerryPi.
- No custom Digitakt firmware or Overbridge integration in this project.
- Do not assume the iRig works on Linux or that full multi-voice capacity is available until measured.
- Add Quarks or UGen packs only when selected after the first stable audio milestone.
- Machine-level audio and MIDI settings (output device, channel counts, sample rate, MIDI connections) belong in `startup.scd` on each Pi, not in `taktberry.scd`. A project file that assigns `s.options.*` silently overrides the machine's settings, and a `nil` assignment resets them to the default. Before adding any such line, state what it overrides, what happens on a machine that lacks it, and how it was verified; prefer reading the setting and warning over assigning it. The same applies to the dev Pi and the headless target Pi, so keep their `startup.scd` content in the repo as a documented reference.
- Review pending (2026-11-05): `taktberry.scd` currently sets `s.options.numOutputBusChannels` and `s.options.numInputBusChannels`, and calls `MIDIClient.init` and `MIDIIn.connectAll`. Decide for each whether it moves to `startup.scd` or stays, and record the reason here.



## Research References

The following resources may inform implementation patterns but are not required runtime dependencies:

- Polygome (behavioral reference): https://github.com/monome-community/polygome
- Grid Studies for SuperCollider: https://monome.org/docs/grid/studies/sc/
- Grid Studies SuperCollider Repository: https://github.com/monome/grid-studies-sc
- MonomeSC: https://github.com/monome/MonomeSC

Grid Studies should be reviewed when designing grid interaction models, state management, LED feedback strategies, and controller abstraction layers. The project remains a behavioral port of Polygome rather than a direct adaptation of Grid Studies examples.


## Foundational Influences

The interaction design of Book II is informed by the monome ecosystem, including Grid Studies, MLR, MLRV, Polygome, and related work by Brian Crabtree and Ezra Buchla (tehn). These projects are referenced as examples of alternative approaches to performance, sequencing, and grid-based interaction rather than as direct implementation targets.