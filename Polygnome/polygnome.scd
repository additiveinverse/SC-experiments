(
~pg = (
	bpm: 120,
	defaultBpm: 120,
	stepBeats: 0.25,
	clockMode: \auto,
	clockSource: \internal,
	clockSourceID: nil,
	clockTimeout: 0.5,
	clockIntervals: List.new,
	lastClockAt: nil,
	clockMonitor: nil,
	clockDefs: Array.new,
	transportStopped: false,
	patternCount: 7,
	maxSteps: 8,
	mode: \play,
	hold: false,
	recording: nil,
	recordStartBeat: 0,
	patterns: Array.fill(7, {
		(steps: Array.fill(8, nil), length: 8, playing: false, held: false, generation: 0, task: nil)
	}),
	clock: nil,
	activeTokens: Dictionary.new,
	noteCounts: Dictionary.new,
	liveTokens: Dictionary.new,
	nextToken: 0,
	noteOn: { |note, velocity| "Polygome note on % velocity %".format(note, velocity).postln },
	noteOff: { |note| "Polygome note off %".format(note).postln }
);

~pg.clock = TempoClock(~pg.bpm / 60);

~pg.useInternalClock = {
	~pg.clockSource = \internal;
	~pg.lastClockAt = nil;
	~pg.clockIntervals.clear;
	~pg.bpm = ~pg.defaultBpm;
	~pg.clock.tempo = ~pg.bpm / 60;
};

~pg.onMidiClock = { |srcID|
	var now = SystemClock.seconds;
	var interval;
	if(srcID == ~pg.clockSourceID and: { ~pg.transportStopped.not } and: { ~pg.clockMode == \auto }) {
		if(~pg.lastClockAt.notNil) {
			interval = now - ~pg.lastClockAt;
			if(interval.inclusivelyBetween(0.005, 0.15)) {
				~pg.clockIntervals.add(interval);
				if(~pg.clockIntervals.size > 24) { ~pg.clockIntervals.removeAt(0) };
				if(~pg.clockIntervals.size >= 24) {
					~pg.bpm = (60 / (~pg.clockIntervals.sum / (~pg.clockIntervals.size * 24))).clip(30, 300);
					~pg.clock.tempo = ~pg.bpm / 60;
				};
			} {
				~pg.clockIntervals.clear;
			};
		};
		~pg.lastClockAt = now;
		~pg.clockSource = \external;
	};
};

~pg.checkClockTimeout = {
	if(~pg.clockMode == \auto and: { ~pg.clockSource == \external } and: { ~pg.transportStopped.not } and: { ~pg.lastClockAt.notNil }) {
		if((SystemClock.seconds - ~pg.lastClockAt) > ~pg.clockTimeout) { ~pg.useInternalClock.() };
	};
};

~pg.startClockMonitor = {
	if(~pg.clockMonitor.isNil) {
		~pg.clockMonitor = Routine {
			loop {
				0.1.wait;
				~pg.checkClockTimeout.();
			};
		}.play(SystemClock);
	};
};

~pg.listenClock = { |srcID|
	if(srcID.isNil) {
		"Specify one MIDI source ID; Polygome will not listen to every MIDI input".warn;
		false
	} {
		~pg.stopClockListener.();
		~pg.clockSourceID = srcID;
		~pg.clockDefs = [
			MIDIdef.midiClock(\pgMidiClock, { |source| ~pg.onMidiClock.(source) }, srcID),
			MIDIdef.start(\pgMidiStart, { |source| ~pg.onMidiStart.(source) }, srcID),
			MIDIdef.continue(\pgMidiContinue, { |source| ~pg.onMidiContinue.(source) }, srcID),
			MIDIdef.stop(\pgMidiStop, { |source| ~pg.onMidiStop.(source) }, srcID)
		];
		~pg.startClockMonitor.();
		true
	};
};

~pg.stopClockListener = {
	~pg.clockDefs.do { |def| def.free };
	~pg.clockDefs = Array.new;
	~pg.clockMonitor !? { |monitor| monitor.stop };
	~pg.clockMonitor = nil;
	~pg.clockSourceID = nil;
	~pg.transportStopped = false;
	~pg.useInternalClock.();
};

~pg.onMidiStart = { |srcID|
	if(srcID == ~pg.clockSourceID) {
		~pg.transportStopped = false;
		~pg.clockSource = \external;
		~pg.clockIntervals.clear;
		~pg.lastClockAt = SystemClock.seconds;
	};
};

~pg.onMidiContinue = { |srcID|
	if(srcID == ~pg.clockSourceID) {
		~pg.transportStopped = false;
		~pg.clockSource = \external;
		~pg.clockIntervals.clear;
		~pg.lastClockAt = SystemClock.seconds;
	};
};

~pg.onMidiStop = { |srcID|
	if(srcID == ~pg.clockSourceID) {
		~pg.transportStopped = true;
		~pg.clockSource = \stopped;
		~pg.lastClockAt = nil;
		~pg.panic.();
	};
};

~pg.acquireNote = { |patternIndex, note, velocity|
	var token = ~pg.nextToken;
	var count = ~pg.noteCounts[note] ? 0;
	~pg.nextToken = token + 1;
	~pg.activeTokens[token] = (pattern: patternIndex, note: note);
	~pg.noteCounts[note] = count + 1;
	if(count == 0) { ~pg.noteOn.(note, velocity.clip(1, 127)) };
	token
};

~pg.releaseToken = { |token|
	var owner = ~pg.activeTokens.removeAt(token);
	var count;
	if(owner.notNil) {
		count = (~pg.noteCounts[owner.note] ? 1) - 1;
		if(count <= 0) {
			~pg.noteCounts.removeAt(owner.note);
			~pg.noteOff.(owner.note);
		} {
			~pg.noteCounts[owner.note] = count;
		};
	};
};

~pg.releasePatternNotes = { |patternIndex|
	var tokens = ~pg.activeTokens.keys.select { |token|
		~pg.activeTokens[token].pattern == patternIndex
	};
	tokens.do { |token| ~pg.releaseToken.(token) };
};

~pg.stopPattern = { |patternIndex|
	var pattern = ~pg.patterns.wrapAt(patternIndex);
	pattern.playing = false;
	pattern.generation = pattern.generation + 1;
	pattern.task !? { |task| task.stop };
	pattern.task = nil;
	~pg.releasePatternNotes.(patternIndex);
};

~pg.startPattern = { |patternIndex|
	var pattern = ~pg.patterns.wrapAt(patternIndex);
	var generation;
	~pg.stopPattern.(patternIndex);
	pattern.generation = pattern.generation + 1;
	generation = pattern.generation;
	pattern.playing = true;
	pattern.task = Routine {
		var step = 0;
		var event;
		while { pattern.playing and: { pattern.generation == generation } and: { ~pg.transportStopped.not } } {
			event = pattern.steps[step];
			if(event.notNil and: { event.active }) {
				var token = ~pg.acquireNote.(patternIndex, event.note, event.velocity);
				~pg.clock.sched(event.duration * ~pg.stepBeats, {
					~pg.releaseToken.(token);
					nil
				});
			};
			~pg.clock.sleep(~pg.stepBeats);
			step = (step + 1) % pattern.length;
		};
	}.play(~pg.clock);
};

~pg.patternDown = { |patternIndex|
	var pattern = ~pg.patterns.wrapAt(patternIndex);
	if(~pg.transportStopped.not) {
		pattern.held = true;
		if(pattern.playing.not) { ~pg.startPattern.(patternIndex) };
	};
};

~pg.patternUp = { |patternIndex|
	var pattern = ~pg.patterns.wrapAt(patternIndex);
	pattern.held = false;
	if(~pg.hold.not) { ~pg.stopPattern.(patternIndex) };
};

~pg.setHold = { |enabled|
	~pg.hold = enabled.asBoolean;
	if(~pg.hold.not) {
		~pg.patterns.do { |pattern, index|
			if(pattern.held.not) { ~pg.stopPattern.(index) };
		};
	};
};

~pg.recordStart = { |patternIndex|
	var pattern = ~pg.patterns.wrapAt(patternIndex);
	~pg.stopPattern.(patternIndex);
	pattern.steps = Array.fill(~pg.maxSteps, nil);
	~pg.recording = patternIndex;
	~pg.recordStartBeat = ~pg.clock.beats;
	~pg.mode = \record;
};

~pg.recordPad = { |note, velocity = 100|
	var patternIndex = ~pg.recording;
	var pattern;
	var elapsed;
	var step;
	if(patternIndex.notNil) {
		pattern = ~pg.patterns[patternIndex];
		elapsed = (~pg.clock.beats - ~pg.recordStartBeat).max(0);
		step = (elapsed / ~pg.stepBeats).round.asInteger % pattern.length;
		pattern.steps[step] = (note: note.clip(0, 127), velocity: velocity.clip(1, 127), duration: 1, active: true);
	};
};

~pg.liveDown = { |note, velocity = 100|
	var token;
	if(~pg.mode == \record) { ~pg.recordPad.(note, velocity) };
	token = ~pg.acquireNote.(nil, note.clip(0, 127), velocity);
	~pg.liveTokens[note] = token;
};

~pg.liveUp = { |note|
	var token = ~pg.liveTokens.removeAt(note);
	if(token.notNil) { ~pg.releaseToken.(token) };
};

~pg.setMode = { |mode|
	var allowed = [\off, \play, \record, \velocity, \durationStep];
	if(allowed.includes(mode)) {
		~pg.mode = mode;
		if(mode != \record) { ~pg.recording = nil };
		if(mode == \off) { ~pg.panic.() };
	} {
		"Unknown Polygome mode: %".format(mode).warn;
	};
};

~pg.setLoopLength = { |patternIndex, length|
	~pg.patterns.wrapAt(patternIndex).length = length.clip(1, ~pg.maxSteps).asInteger;
};

~pg.setVelocity = { |patternIndex, step, velocity|
	var event = ~pg.patterns.wrapAt(patternIndex).steps.wrapAt(step);
	if(event.notNil) { event.velocity = velocity.clip(1, 127) };
};

~pg.setDuration = { |patternIndex, step, durationSteps|
	var event = ~pg.patterns.wrapAt(patternIndex).steps.wrapAt(step);
	if(event.notNil) { event.duration = durationSteps.clip(1, ~pg.maxSteps).asInteger };
};

~pg.setStepActive = { |patternIndex, step, active|
	var event = ~pg.patterns.wrapAt(patternIndex).steps.wrapAt(step);
	if(event.notNil) { event.active = active.asBoolean };
};

~pg.setTempo = { |bpm|
	~pg.defaultBpm = bpm.clip(30, 300);
	if(~pg.clockSource != \external) {
		~pg.bpm = ~pg.defaultBpm;
		~pg.clock.tempo = ~pg.bpm / 60;
	};
};

~pg.connectTaktBerry = {
	if(~synthOn.notNil and: { ~synthOff.notNil }) {
		~pg.noteOn = { |note, velocity| ~synthOn.(note, velocity) };
		~pg.noteOff = { |note| ~synthOff.(note) };
		true
	} {
		"Load taktberry.scd before connecting the Polygome note callbacks".warn;
		false
	};
};

~pg.panic = {
	~pg.patterns.do { |pattern, index|
		pattern.held = false;
		~pg.stopPattern.(index);
	};
	~pg.liveTokens.keys.do { |note| ~pg.liveUp.(note) };
	~pg.recording = nil;
};

"Polygome core ready: seven patterns, eight steps, no server or MIDI settings changed".postln;
)