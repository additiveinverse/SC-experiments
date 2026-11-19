// Run the whole block; then try the examples at the bottom.
(
~numLanes = 6;
~numSteps = 8;
~quant = 0.5; // beats, 0 = cut immediately
~bpm = 120;

s.waitForBoot {
	~clock = TempoClock(~bpm / 60);
	~bufs = Array.newClear(~numLanes);
	~synths = Array.newClear(~numLanes);
	~playhead = Array.fill(~numLanes, 0);

	SynthDef(\mlrLane, { |out = 0, buf, beats = 4, bpm = 120, amp = 0.5, pos = 0, t_cut = 0, lane = 0|
		var frames = BufFrames.kr(buf);
		var rate = BufDur.kr(buf) * bpm / (60 * beats);
		var phase = Phasor.ar(t_cut, BufRateScale.kr(buf) * rate, 0, frames, pos * frames);
		var sig = BufRd.ar(1, buf, phase, 1, 2) * amp;
		SendReply.kr(Impulse.kr(30), '/mlrPos', phase / frames, lane);
		Out.ar(out, sig ! 2);
	}).add;

	OSCdef(\mlrPos, { |msg|
		~playhead[msg[2].asInteger] = (msg[3] * ~numSteps).floor.asInteger.clip(0, ~numSteps - 1);
	}, '/mlrPos');

	// A loop of `beats` beats; rate is derived so the buffer fits the tempo.
	~startLane = { |lane, buf, beats = 4|
		~synths[lane] !? { |old| old.free };
		~bufs[lane] = buf;
		~synths[lane] = Synth(\mlrLane, [\buf, buf, \lane, lane, \beats, beats, \bpm, ~bpm]);
	};

	~cut = { |lane, step|
		var go = { s.bind { ~synths[lane].set(\pos, step / ~numSteps, \t_cut, 1) } };
		if(~quant > 0) {
			~clock.schedAbs(~clock.nextTimeOnGrid(~quant), { go.value; nil });
		} {
			go.value;
		};
	};

	// Each step is a different pitch so cuts are audible without any sample files.
	~testLoop = {
		var sr = s.sampleRate, n = (sr * 2).asInteger, len = (n / ~numSteps).asInteger;
		var sig = Signal.newClear(n);
		~numSteps.do { |i|
			len.do { |j| sig[i * len + j] = sin(2pi * 110 * (i + 1) * j / sr) * (1 - (j / len)) * 0.4 };
		};
		Buffer.loadCollection(s, sig);
	};

	// Left channel only; the old buffer is freed once the new one is playing.
	~loadLane = { |lane, path, beats = 4|
		var old = ~bufs[lane];
		~bufs[lane] = Buffer.readChannel(s, path, channels: [0], action: { |b|
			~startLane.(lane, b, beats);
			old !? { |o| o.free };
		});
	};

	// `beats` can be one number or an array with one entry per file.
	~loadFolder = { |dir, beats = 4|
		var exts = ["wav", "aif", "aiff", "flac"];
		var files = PathName(dir).files
			.select { |f| exts.includes(f.extension.toLower) }
			.sort { |a, b| a.fileName < b.fileName }
			.first(~numLanes);
		files.do { |f, i| ~loadLane.(i, f.fullPath, beats.asArray.wrapAt(i)) };
		files.collect(_.fileName).postln;
	};

	~bufs[0] = ~testLoop.value;
	s.sync;
	~startLane.(0, ~bufs[0], 4);
	"mlr engine ready: lane 0 looping".postln;
};
)

// // Examples
// ~cut.(0, 3);
// ~cut.(0, 6);
// ~playhead[0];
// ~quant = 0; // immediate cuts

// Loading: use forward slashes in Windows paths.
~loadLane.(0, "C:/path/to/loop.wav", 4);
~loadFolder.("C:/path/to/loops", 4);
~loadFolder.("C:/path/to/loops", [4, 4, 8, 2, 4, 4]);
