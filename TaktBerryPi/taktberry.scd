// taktBerryPi phase one: 6 note-per-voice drums (omni) + one 4-note synth slot.
// Headless: sclang taktberry.scd   |   IDE: select all and run.

(
~cfg = (
	drumNotes: [36, 37, 38, 39, 40, 41], // lowest six pads; probe with SC_MLRV/midi_probe.scd and edit
	synthChans: [14],                    // 0-indexed MIDI channels; 14 = channel 15
	synthVoices: 4,
	ccBase: 20,                          // drum CC block: ccBase + voice * 6 + paramIndex
	uiAddr: nil                          // e.g. NetAddr("192.168.1.50", 9000) for TouchOSC feedback
);

~paramNames = [\level, \tune, \decay, \pan, \mix, \tone];
~specs = (
	level: ControlSpec(0, 1),
	tune: ControlSpec(-24, 24),
	decay: ControlSpec(0.03, 2, \exp),
	pan: ControlSpec(-1, 1),
	mix: ControlSpec(0, 1),      // 0 = synth layer, 1 = sample layer
	tone: ControlSpec(200, 18000, \exp)
);
~drumDefaults = (level: 0.8, tune: 0, decay: 0.3, pan: 0, mix: 0, tone: 12000);

s.waitForBoot {
	SynthDef(\tbDrum, { |out = 0, buf, gate = 1, vel = 1, level = 0.8, tune = 0, decay = 0.3, pan = 0, mix = 0, tone = 12000|
		var ratio = tune.midiratio;
		var env = EnvGen.kr(Env.perc(0.001, decay, 1, -4), doneAction: 2);
		var kill = EnvGen.kr(Env.asr(0, 1, 0.01), gate, doneAction: 2);
		var body = SinOsc.ar(50 * ratio * XLine.kr(4, 1, 0.04));
		var click = WhiteNoise.ar * EnvGen.kr(Env.perc(0.0005, 0.01)) * 0.3;
		var smp = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * ratio);
		var sig = XFade2.ar(body + click, smp, mix * 2 - 1);
		sig = LPF.ar(sig, tone) * env * kill * vel * level;
		Out.ar(out, Pan2.ar(sig, pan));
	}).add;

	SynthDef(\tbSub, { |out = 0, gate = 1, freq = 220, amp = 0.2, cutoff = 3000, res = 0.2, atk = 0.005, dec = 0.2, sus = 0.6, rel = 0.3, pan = 0|
		var env = EnvGen.kr(Env.adsr(atk, dec, sus, rel), gate, doneAction: 2);
		var sig = Saw.ar(freq) + Pulse.ar(freq * 1.005, 0.5);
		sig = RLPF.ar(sig, (cutoff * (1 + env)).clip(20, 18000), (1 - res).clip(0.1, 1));
		Out.ar(out, Pan2.ar(sig * env * amp * 0.5, pan));
	}).add;

	// Safety limiter so stacked voices cannot clip the output.
	SynthDef(\tbMaster, { |in, out = 0|
		Out.ar(out, Limiter.ar(In.ar(in, 2), 0.9, 0.005));
	}).add;

	s.sync;

	~bus = Bus.audio(s, 2);
	~srcGroup = Group(s);
	~master = Synth.after(~srcGroup, \tbMaster, [\in, ~bus]);

	~silent = Buffer.alloc(s, 1, 1);
	~drumBuf = Array.fill(6, { ~silent });
	~drumP = Array.fill(6, { ~drumDefaults.copy });
	~drumNode = Array.fill(6, nil);
	~slots = Array.fill(~cfg.synthVoices, { (note: nil, node: nil, age: 0) });
	~age = 0;

	~loadSample = { |voice, path|
		~drumBuf[voice] = Buffer.readChannel(s, path, channels: [0]);
	};

	~drumTrig = { |v, vel = 127|
		var old = ~drumNode[v];
		if(old.notNil and: { old.isPlaying }) { old.release(0.005) };
		~drumNode[v] = Synth(\tbDrum,
			[\out, ~bus, \buf, ~drumBuf[v], \vel, vel / 127] ++ ~drumP[v].getPairs,
			~srcGroup).register;
	};

	~synthOn = { |note, vel|
		var i = ~slots.detectIndex { |sl| sl.note == note };
		var order, sl;
		i = i ?? {
			order = (0..~slots.size - 1).sort { |a, b| ~slots[a].age <= ~slots[b].age };
			order.detect { |k| ~slots[k].note.isNil } ?? { order.first }
		};
		sl = ~slots[i];
		if(sl.node.notNil and: { sl.node.isPlaying }) { sl.node.release(0.02) };
		~age = ~age + 1;
		sl.note = note;
		sl.age = ~age;
		sl.node = Synth(\tbSub,
			[\out, ~bus, \freq, note.midicps, \amp, (vel / 127).squared * 0.5],
			~srcGroup).register;
	};

	~synthOff = { |note|
		var sl = ~slots.detect { |x| x.note == note };
		if(sl.notNil) {
			if(sl.node.notNil and: { sl.node.isPlaying }) { sl.node.release };
			sl.note = nil;
		};
	};

	~panic = {
		~srcGroup.freeAll;
		~slots.do { |sl| sl.note = nil; sl.node = nil };
		~drumNode = Array.fill(6, nil);
		"panic".postln;
	};

	~reply = { |path, val| ~cfg.uiAddr !? { |a| a.sendMsg(path, val) } };

	// MIDI: drum notes match on any non-synth channel; CC block per voice; CC 120/123 = panic.
	MIDIdef.noteOn(\tbOn, { |vel, note, ch|
		var v;
		if(~cfg.synthChans.includes(ch)) { ~synthOn.(note, vel) } {
			v = ~cfg.drumNotes.indexOf(note);
			if(v.notNil) { ~drumTrig.(v, vel) };
		};
	});
	MIDIdef.noteOff(\tbOff, { |vel, note, ch|
		if(~cfg.synthChans.includes(ch)) { ~synthOff.(note) };
	});
	MIDIdef.cc(\tbCC, { |val, num, ch|
		var idx, name;
		if(num == 120 or: { num == 123 }) { ~panic.() } {
			idx = num - ~cfg.ccBase;
			if(idx.inclusivelyBetween(0, 6 * ~paramNames.size - 1) and: { ~cfg.synthChans.includes(ch).not }) {
				name = ~paramNames[idx % ~paramNames.size];
				~drumP[idx div: ~paramNames.size][name] = ~specs[name].map(val / 127);
			};
		};
	});

	// OSC: /taktberry/drum/{1-6}/{param} <value in real units>, /trig [vel], /get; /taktberry/panic.
	6.do { |v|
		~paramNames.do { |name|
			var path = "/taktberry/drum/%/%".format(v + 1, name).asSymbol;
			OSCdef(path, { |msg|
				~drumP[v][name] = msg[1];
				~reply.(path, msg[1]);
			}, path);
		};
		OSCdef(("/taktberry/drum/%/trig".format(v + 1)).asSymbol, { |msg|
			~drumTrig.(v, msg[1] ? 127);
		}, "/taktberry/drum/%/trig".format(v + 1).asSymbol);
		OSCdef(("/taktberry/drum/%/get".format(v + 1)).asSymbol, {
			~paramNames.do { |name|
				~reply.("/taktberry/drum/%/%".format(v + 1, name).asSymbol, ~drumP[v][name]);
			};
		}, "/taktberry/drum/%/get".format(v + 1).asSymbol);
	};
	OSCdef(\tbPanic, { ~panic.() }, '/taktberry/panic');

	// Load report for the measurement step.
	Routine {
		loop {
			5.wait;
			// "cpu avg % peak % synths % %".format(
			// 	s.avgCPU.round(0.1), s.peakCPU.round(0.1), s.numSynths,
			// 	if(thisProcess.platform.name == \linux) {
			// 		"vcgencmd measure_temp".unixCmdGetStdOut.stripWhiteSpace
			// 	} { "" }
			// ).postln;
		}
	}.play(AppClock);

	"taktBerryPi ready".postln;
};
)

// Local tests (run line by line):
// ~drumTrig.(0, 100);
// ~synthOn.(60, 100); ~synthOff.(60);
// ~panic.();
// s.quit; // stop the server if needed
// s.freeAll; // free all nodes if needed