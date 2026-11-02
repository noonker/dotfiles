// What both background shaders share: noise, the knife, and an alphabet.
float fill(float d, float aa) {
    return smoothstep(aa, -aa, d);
}

// After Dave Hoskins' "hash without sine".
float hash(vec2 p) {
    vec3 q = fract(p.xyx * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

#ifdef BAKE

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0, amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p = p * 2.03 + vec2(17.0, 9.0);
        amplitude *= 0.5;
    }
    return value;
}

// Distance to the quadratic Bézier through a, b and c, and how far along it (after Inigo Quilez).
vec2 curve(vec2 pos, vec2 pa, vec2 pb, vec2 pc) {
    vec2 ctrl = 2.0 * pb - 0.5 * (pa + pc);
    vec2 a = ctrl - pa;
    vec2 b = pa - 2.0 * ctrl + pc;
    vec2 c = a * 2.0;
    vec2 d = pa - pos;
    float kk = 1.0 / max(dot(b, b), 1e-9);
    float kx = kk * dot(a, b);
    float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
    float kz = kk * dot(d, a);
    float p = ky - kx * kx;
    float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
    float h = q * q + 4.0 * p * p * p;
    if (h >= 0.0) {
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x) * pow(abs(x), vec2(1.0 / 3.0));
        float t = clamp(uv.x + uv.y - kx, 0.0, 1.0);
        vec2 w = d + (c + b * t) * t;
        return vec2(length(w), t);
    }
    float z = sqrt(-p);
    float v = acos(q / (p * z * 2.0)) / 3.0;
    float m = cos(v), n = sin(v) * 1.732050808;
    vec2 t = clamp(vec2(m + m, -n - m) * z - kx, 0.0, 1.0);
    vec2 wx = d + (c + b * t.x) * t.x, wy = d + (c + b * t.y) * t.y;
    float dx = dot(wx, wx), dy = dot(wy, wy);
    return dx < dy ? vec2(sqrt(dx), t.x) : vec2(sqrt(dy), t.y);
}

// A cut with the knife: w0 thick at its ends and swelling to w1 along the way.
float cut(vec2 p, vec2 a, vec2 b, vec2 c, float w0, float w1) {
    vec2 h = curve(p, a, b, c);
    return h.x - mix(w0, w1, sin(PI * h.y));
}

float bar(vec2 p, vec2 a, vec2 b, float w0, float w1) {
    vec2 pa = p - a, ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * t) - mix(w0, w1, t);
}

// Letters a unit tall and about 0.65 wide, cut with a broad stem and hairline serifs.
const float STEM = 0.078, THIN = 0.024;

float serifs(vec2 p, float x, float width) {
    return min(bar(p, vec2(x - width, 0.985), vec2(x + width, 0.985), THIN, THIN),
               bar(p, vec2(x - width, 0.015), vec2(x + width, 0.015), THIN, THIN));
}

float letterL(vec2 p) {
    float d = min(bar(p, vec2(0.17, 0.02), vec2(0.17, 0.98), STEM, STEM), serifs(p - vec2(0.0, 0.0), 0.17, 0.16));
    d = min(d, bar(p, vec2(0.17, 0.03), vec2(0.60, 0.03), THIN + 0.012, THIN));
    return min(d, bar(p, vec2(0.60, 0.02), vec2(0.62, 0.26), THIN, THIN * 0.6));
}

float letterE(vec2 p) {
    float d = letterL(p);
    d = min(d, bar(p, vec2(0.17, 0.97), vec2(0.56, 0.97), THIN + 0.012, THIN));
    d = min(d, bar(p, vec2(0.56, 0.98), vec2(0.58, 0.76), THIN, THIN * 0.6));
    d = min(d, bar(p, vec2(0.17, 0.52), vec2(0.44, 0.52), THIN + 0.006, THIN));
    return min(d, bar(p, vec2(0.44, 0.40), vec2(0.44, 0.64), THIN * 0.7, THIN * 0.7));
}

float letterI(vec2 p) {
    return min(bar(p, vec2(0.17, 0.02), vec2(0.17, 0.98), STEM, STEM), serifs(p, 0.17, 0.16));
}

float letterO(vec2 p) {
    vec2 q = p - vec2(0.36, 0.5);
    float outer = (length(q / vec2(0.36, 0.52)) - 1.0) * 0.36;
    float inner = (length(q / vec2(0.19, 0.45)) - 1.0) * 0.19;
    return max(outer, -inner);
}

float letterS(vec2 p) {
    float d = cut(p, vec2(0.50, 0.96), vec2(0.28, 1.0), vec2(0.08, 0.74), THIN, STEM * 0.8);
    d = min(d, cut(p, vec2(0.08, 0.74), vec2(0.30, 0.50), vec2(0.50, 0.26), STEM * 0.5, STEM));
    d = min(d, cut(p, vec2(0.50, 0.26), vec2(0.28, 0.0), vec2(0.05, 0.05), STEM * 0.8, THIN));
    d = min(d, bar(p, vec2(0.50, 0.70), vec2(0.50, 0.98), THIN, THIN));
    return min(d, bar(p, vec2(0.05, 0.02), vec2(0.05, 0.28), THIN, THIN));
}

float letterA(vec2 p) {
    float d = min(bar(p, vec2(0.05, 0.03), vec2(0.34, 0.98), THIN, THIN), bar(p, vec2(0.34, 0.98), vec2(0.63, 0.03), STEM * 0.8, STEM));
    d = min(d, bar(p, vec2(0.15, 0.32), vec2(0.52, 0.32), THIN, THIN));
    d = min(d, bar(p, vec2(-0.04, 0.015), vec2(0.15, 0.015), THIN, THIN));
    return min(d, bar(p, vec2(0.50, 0.015), vec2(0.76, 0.015), THIN, THIN));
}

float letterR(vec2 p) {
    float d = min(bar(p, vec2(0.17, 0.02), vec2(0.17, 0.98), STEM, STEM), serifs(p, 0.17, 0.16));
    d = min(d, cut(p, vec2(0.17, 0.97), vec2(0.60, 0.74), vec2(0.17, 0.50), THIN, STEM * 0.85));
    return min(d, bar(p, vec2(0.28, 0.50), vec2(0.60, 0.03), STEM * 0.6, STEM));
}

float letterV(vec2 p) {
    float d = min(bar(p, vec2(0.05, 0.97), vec2(0.34, 0.03), STEM, STEM * 0.6), bar(p, vec2(0.34, 0.03), vec2(0.64, 0.97), THIN, THIN));
    d = min(d, bar(p, vec2(-0.05, 0.985), vec2(0.20, 0.985), THIN, THIN));
    return min(d, bar(p, vec2(0.52, 0.985), vec2(0.74, 0.985), THIN, THIN));
}

float letterD(vec2 p) {
    float d = min(bar(p, vec2(0.17, 0.02), vec2(0.17, 0.98), STEM, STEM), serifs(p, 0.17, 0.16));
    return min(d, cut(p, vec2(0.17, 0.975), vec2(0.70, 0.5), vec2(0.17, 0.025), THIN, STEM * 1.05));
}

float letterF(vec2 p) {
    float d = min(bar(p, vec2(0.17, 0.02), vec2(0.17, 0.98), STEM, STEM), serifs(p, 0.17, 0.16));
    d = min(d, bar(p, vec2(0.17, 0.97), vec2(0.56, 0.97), THIN + 0.012, THIN));
    d = min(d, bar(p, vec2(0.56, 0.98), vec2(0.58, 0.76), THIN, THIN * 0.6));
    d = min(d, bar(p, vec2(0.17, 0.50), vec2(0.44, 0.50), THIN + 0.006, THIN));
    return min(d, bar(p, vec2(0.44, 0.38), vec2(0.44, 0.62), THIN * 0.7, THIN * 0.7));
}

float letterT(vec2 p) {
    float d = min(bar(p, vec2(0.34, 0.02), vec2(0.34, 0.98), STEM, STEM), bar(p, vec2(0.0, 0.97), vec2(0.68, 0.97), THIN + 0.012, THIN + 0.012));
    d = min(d, bar(p, vec2(0.0, 0.98), vec2(-0.01, 0.76), THIN, THIN * 0.6));
    d = min(d, bar(p, vec2(0.68, 0.98), vec2(0.69, 0.76), THIN, THIN * 0.6));
    return min(d, bar(p, vec2(0.20, 0.015), vec2(0.48, 0.015), THIN, THIN));
}

float letterN(vec2 p) {
    float d = min(bar(p, vec2(0.08, 0.02), vec2(0.08, 0.98), THIN, THIN), bar(p, vec2(0.60, 0.02), vec2(0.60, 0.98), THIN, THIN));
    d = min(d, bar(p, vec2(0.08, 0.96), vec2(0.60, 0.04), STEM, STEM * 0.8));
    d = min(d, bar(p, vec2(-0.03, 0.015), vec2(0.19, 0.015), THIN, THIN));
    d = min(d, bar(p, vec2(-0.03, 0.985), vec2(0.10, 0.985), THIN, THIN));
    return min(d, bar(p, vec2(0.49, 0.985), vec2(0.72, 0.985), THIN, THIN));
}

#endif
