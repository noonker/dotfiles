// SuperCollider startup file managed by Guix home configuration.
// Tuned for TidalCycles / SuperDirt: SuperDirt loads >200 sample banks,
// which blows past scsynth's default buffer/memory limits.

s.options.numBuffers = 1024 * 256;
s.options.memSize    = 8192 * 32;
s.options.maxNodes   = 1024 * 32;
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels  = 2;
