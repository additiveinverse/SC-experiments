// Run block 1, then press pads and buttons on the Launchpad Pro MK3 and read the post window.
(
MIDIClient.init;
MIDIClient.sources.do { |src, i| "% : % / %".format(i, src.device, src.name).postln };
)

(
MIDIIn.connectAll;
MIDIdef.noteOn(\probeOn, { |vel, note, ch, src| ["noteOn", note, vel, ch, src].postln });
MIDIdef.noteOff(\probeOff, { |vel, note, ch, src| ["noteOff", note, vel, ch, src].postln });
MIDIdef.cc(\probeCC, { |val, num, ch, src| ["cc", num, val, ch, src].postln });
)

// Run to stop probing.
MIDIdef(\probeOn).free; MIDIdef(\probeOff).free; MIDIdef(\probeCC).free;
