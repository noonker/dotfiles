// Renders the theme's sounds to the WAV files beside this script, without a server:
//   cd channels/noonker/home/theme/sounds && QT_QPA_PLATFORM=offscreen sclang render.scd
(
var dir = thisProcess.nowExecutingPath.dirname;
var defs = [
    // A struck bell: inharmonic partials, the upper ones dying first.
    SynthDef(\bell, { |freq = 440, amp = 0.2, dec = 3, pan = 0|
        var partials = [0.5, 1, 1.19, 2, 2.76, 5.4];
        var levels = [0.5, 1, 0.45, 0.5, 0.2, 0.08];
        var sig = Mix(partials.collect { |p, i|
            SinOsc.ar(freq * p) * levels[i]
            * EnvGen.ar(Env.perc(0.003, dec / (1 + (i * 0.6))))
        });
        Line.kr(0, 0, dec * 1.2, doneAction: 2);
        Out.ar(0, sig * amp);
    }),
    // A card put down on wood, and a thump under it.
    SynthDef(\snap, { |amp = 0.4, tone = 2400, knock = 150|
        var click = BPF.ar(WhiteNoise.ar, tone, 0.9) * EnvGen.ar(Env.perc(0.0005, 0.035));
        var body = SinOsc.ar(XLine.kr(knock * 1.6, knock, 0.04))
                   * EnvGen.ar(Env.perc(0.001, 0.09), doneAction: 2);
        Out.ar(0, (click * 1.4 + (body * 0.8)) * amp);
    }),
    // The room: everything on bus 0, in a little reverb, written back.
    SynthDef(\room, { |mix = 0.3, size = 0.7|
        ReplaceOut.ar(0, FreeVerb.ar(In.ar(0), mix, size, 0.4));
    })
];
var bell = { |time, freq, amp, dec|
    [time, [\s_new, \bell, -1, 0, 0, \freq, freq, \amp, amp, \dec, dec]]
};
var sounds = (
    // Sunrise: a rising fifth and octave, bright and unhurried.
    'chime-day': (dur: 4, mix: 0.25, size: 0.6, notes: [
        bell.(0.0, 659.26, 0.14, 2.2), bell.(0.28, 987.77, 0.11, 2.2),
        bell.(0.56, 1318.51, 0.09, 2.6)
    ]),
    // Sunset: a falling, lower pair in a bigger room.
    'chime-night': (dur: 5.5, mix: 0.45, size: 0.9, notes: [
        bell.(0.0, 523.25, 0.13, 3.0), bell.(0.5, 349.23, 0.15, 3.8)
    ]),
    // A dry card on the table by day; a softer, darker one by night.
    'lock-day': (dur: 0.5, mix: 0.08, size: 0.2, notes: [
        [0.0, [\s_new, \snap, -1, 0, 0, \amp, 0.42, \tone, 2600, \knock, 170]]
    ]),
    'lock-night': (dur: 0.9, mix: 0.3, size: 0.6, notes: [
        [0.0, [\s_new, \snap, -1, 0, 0, \amp, 0.3, \tone, 1300, \knock, 110]]
    ])
);
var remaining = sounds.size;
var options = ServerOptions.new.numOutputBusChannels_(1).verbosity_(-1);

sounds.keysValuesDo { |name, sound|
    var setup = defs.collect { |def| [0.0, [\d_recv, def.asBytes]] };
    var room = [0.0, [\s_new, \room, 1000, 1, 0, \mix, sound.mix, \size, sound.size]];
    var osc = PathName.tmp +/+ "theme-%.osc".format(name);
    Score.recordNRT(
        setup ++ sound.notes ++ [room, [sound.dur, [\c_set, 0, 0]]],
        osc, dir +/+ "%.wav".format(name),
        sampleRate: 44100, headerFormat: "WAV", sampleFormat: "int16",
        options: options, duration: sound.dur,
        action: {
            remaining = remaining - 1;
            if (remaining == 0) { 0.exit };
        }
    );
};
)
