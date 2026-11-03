#!/usr/bin/env python3
"""The Marseille and Arcana cursor themes, drawn here and built along with the home.

Each cursor is drawn once and printed two ways.  Marseille cuts it like the deck's woodblocks: a
key line that swells away from the light, comb hatching, and stencil color a little out of
register.  Arcana gilds it like the night wallpaper's rose: flat facets of gold, violet enamel, and
the same ramp of gold.  Everything is worked out on the page after turning, so the light stays
up and to the left whichever way a cursor points.

What niri does decides a few things here:

- It asks for its xcursor-size (34) times the output's scale rounded up.  So the panel (1.5) and
  the Studio Display (2) both use the 68px image, and the GPU draws it down to 51px on the panel.
  So the 68px image is the one that matters, and hatching of about 1 unit is the finest that lasts.
- It divides the hotspot by that scale in whole pixels, so hotspots should be even at 68px.
- It repaints the output at full rate for as long as an animated cursor is showing, so only
  `wait` and `progress` move, however nice a twinkling star would be.

Run it with --svg to get the pictures alone, to look at.
"""
import argparse
import cmath
import math
import os
import re
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor

# 24, 48 and 51 are for clients with their own ideas, 34 for scale 1, 102 for scale 3.
SIZES = (24, 34, 48, 51, 68, 102)
OVERSAMPLE = 6                  # the GPU's scaling softens it, so downsample with some bite
FRAMES = 36
FRAME_MS = 70

TAU = 2 * math.pi
TIP = 4 + 4j
HAND_TIP = 6 + 4j
LENS = 26.4 + 26.4j
CENTER = 32 + 32j


def turn(degrees):
    return cmath.exp(1j * math.radians(degrees))


LIGHT = turn(-125)              # where the light comes from


def faces_light(normal):
    return normal.real * LIGHT.real + normal.imag * LIGHT.imag


# ---- Shapes: lists of polylines of complex numbers, y down, in a 64-unit square ------------------

def parse(path, steps=14):
    """Flatten SVG path data (M L C Q Z, absolute only) into a shape."""
    tokens = re.findall(r'[MLCQZ]|-?\d*\.?\d+(?:e-?\d+)?', path)
    i, shape, cur, here, start, cmd = 0, [], [], 0j, 0j, 'M'

    def point():
        nonlocal i
        i += 2
        return complex(float(tokens[i - 2]), float(tokens[i - 1]))

    while i < len(tokens):
        if tokens[i].isalpha():
            cmd = tokens[i]
            i += 1
        if cmd == 'M':
            if cur:
                shape.append(cur)
            here = start = point()
            cur = [here]
            cmd = 'L'
        elif cmd == 'L':
            here = point()
            cur.append(here)
        elif cmd == 'C':
            a, b, e = point(), point(), point()
            for k in range(1, steps + 1):
                t = k / steps
                u = 1 - t
                cur.append(u*u*u*here + 3*u*u*t*a + 3*u*t*t*b + t*t*t*e)
            here = e
        elif cmd == 'Q':
            a, e = point(), point()
            for k in range(1, steps + 1):
                t = k / steps
                u = 1 - t
                cur.append(u*u*here + 2*u*t*a + t*t*e)
            here = e
        elif cmd == 'Z':
            shape.append(cur + [start])
            cur = []
            here = start
    if cur:
        shape.append(cur)
    return shape


def line(path, steps=14):
    return parse(path, steps)[0]


def circle(c, r, n=48):
    return [[c + r * cmath.exp(1j * TAU * k / n) for k in range(n)] + [c + r]]


def ellipse(c, rx, ry, degrees=0, n=20):
    w = turn(degrees)
    return [[c + w * complex(rx * math.cos(TAU * k / n), ry * math.sin(TAU * k / n)) for k in range(n + 1)]]


def ring(c, outer, inner):
    return [circle(c, outer)[0], circle(c, inner)[0][::-1]]


def sector(c, inner, outer, a0, a1, n=24):
    """A piece of a ring, between two angles."""
    out = [c + outer * turn(a0 + (a1 - a0) * k / n) for k in range(n + 1)]
    back = [c + inner * turn(a1 - (a1 - a0) * k / n) for k in range(n + 1)]
    return [out + back + [out[0]]]


def capsule(a, b, ra, rb, n=10):
    """A finger: from A, out to a round end at B."""
    u = (b - a) / abs(b - a)
    m = u * 1j
    pts = [a - m * ra]
    pts += [b - rb * m * cmath.exp(1j * math.pi * k / n) for k in range(n + 1)]
    return [pts + [a + m * ra, a - m * ra]]


def star(c, r, waist, points=4, degrees=0):
    w = turn(degrees)
    pts = []
    for k in range(points * 2):
        a = cmath.exp(1j * (TAU * k / (points * 2) - math.pi / 2))
        pts.append(c + w * a * (r if k % 2 == 0 else waist))
    return [pts + [pts[0]]]


def bar(a, b, width):
    n = (b - a) / abs(b - a) * 1j * width / 2
    return [[a + n, b + n, b - n, a - n, a + n]]


def xf(shape, at=0j, degrees=0, scale=1):
    """Scale and turn a shape or polyline, then move it."""
    w = turn(degrees) * scale
    if shape and isinstance(shape[0], list):
        return [[at + w * p for p in sub] for sub in shape]
    return [at + w * p for p in shape]


def reflect_x(shape):
    return [[complex(-p.real, p.imag) for p in sub] for sub in shape]


def reflect_y(shape):
    return [[p.conjugate() for p in sub] for sub in shape]


def path_data(shape):
    return ''.join(
        'M' + 'L'.join(f'{p.real:.3f} {p.imag:.3f}' for p in sub) + ('Z' if abs(sub[0] - sub[-1]) < 1e-6 else '')
        for sub in shape)


def even_points(points, count):
    lengths = [0.0]
    for a, b in zip(points, points[1:]):
        lengths.append(lengths[-1] + abs(b - a))
    out, j = [], 0
    for k in range(count):
        s = lengths[-1] * (k + 0.5) / count
        while j < len(lengths) - 2 and lengths[j + 1] < s:
            j += 1
        out.append(points[j] + (points[j + 1] - points[j]) * ((s - lengths[j]) / ((lengths[j + 1] - lengths[j]) or 1)))
    return out


def normals(points, closed=False):
    n = len(points)
    out = []
    for i in range(n):
        if closed:
            a, b = points[(i - 1) % (n - 1)], points[(i + 1) % (n - 1)]
        else:
            a, b = points[max(i - 1, 0)], points[min(i + 1, n - 1)]
        t = b - a
        out.append(t / abs(t) * 1j if abs(t) > 1e-9 else 0j)
    return out


# ---- Cuts: strokes that change width, the way a gouge leaves them --------------------------------

def swell(a, b, c):
    """A width that goes through A at the start, B in the middle and C at the end."""
    def width(t):
        u = 1 - t
        return u*u*a + 2*u*t*(2*b - (a + c) / 2) + t*t*c
    return width


def taper(points, width):
    w = width if callable(width) else (lambda t: width)
    n = len(points)
    ns = normals(points)
    left = [p + m * w(i / (n - 1)) / 2 for i, (p, m) in enumerate(zip(points, ns))]
    right = [p - m * w(i / (n - 1)) / 2 for i, (p, m) in enumerate(zip(points, ns))]
    return [left + right[::-1] + [left[0]]]


def contour(shape, thin, heavy, hole=False):
    """A closed outline as a fillable shape: THIN facing the light, HEAVY away from it.  In a HOLE
    it's the other way round, since the far wall of a hole is the one in shadow."""
    out = []
    for sub in shape:
        closed = abs(sub[0] - sub[-1]) < 1e-6
        ns = normals(sub, closed)
        area = sum((a.conjugate() * b).imag for a, b in zip(sub, sub[1:] + sub[:1]))
        sign = (1 if area < 0 else -1) * (-1 if hole else 1)
        widths = []
        for m in ns:
            k = (1 - faces_light(m * sign)) / 2
            widths.append(thin + (heavy - thin) * k * k * (3 - 2 * k))
        outer = [p + m * sign * w / 2 for p, m, w in zip(sub, ns, widths)]
        inner = [p - m * sign * w / 2 for p, m, w in zip(sub, ns, widths)]
        for i in range(len(sub) - 1):
            out.append([outer[i], outer[i + 1], inner[i + 1], inner[i], outer[i]])
    return out


def teeth(along, direction, length, count, width):
    """Comb hatching: wedges that start on a curve and thin out into the light."""
    out = []
    for k, p in enumerate(even_points(along, count)):
        reach = length((k + 0.5) / count) if callable(length) else length
        n = direction * 1j * width / 2
        out.append([p + n, p + direction * reach, p - n, p + n])
    return out


# ---- Color -------------------------------------------------------------------------------------

def rgb(color):
    return tuple(int(color[i:i + 2], 16) / 255 for i in (1, 3, 5))


def to_hex(channels):
    return '#' + ''.join(f'{max(0, min(255, round(v * 255))):02x}' for v in channels)


def mix(a, b, t):
    return to_hex(tuple(x + (y - x) * t for x, y in zip(rgb(a), rgb(b))))


# ---- A picture ---------------------------------------------------------------------------------

class Art:
    """FINE is for the sizes on screen.  Without it, at 24 and 34, hatching would only turn to
    mud, so it's left out and the lines are stronger."""

    def __init__(self, fine=True):
        self.fine = fine
        self.k = 1.0 if fine else 1.3
        self.defs, self.items = [], []

    def _id(self):
        return f'n{len(self.defs)}'

    def fill(self, shape, color, opacity=None, clip=None, rule=None):
        extra = (f' fill-opacity="{opacity}"' if opacity is not None else '') \
            + (f' clip-path="url(#{clip})"' if clip else '') \
            + (f' fill-rule="{rule}"' if rule else '')
        self.items.append(f'<path d="{path_data(shape)}" fill="{color}"{extra}/>')

    def stroke(self, shape, color, width):
        self.items.append(f'<path d="{path_data(shape)}" fill="none" stroke="{color}" stroke-width="{width:.3f}" '
                          'stroke-linejoin="round" stroke-linecap="round"/>')

    def clip(self, shape):
        i = self._id()
        self.defs.append(f'<clipPath id="{i}"><path d="{path_data(shape)}"/></clipPath>')
        return i

    def gradient(self, a, b, stops):
        i = self._id()
        body = ''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
        self.defs.append(f'<linearGradient id="{i}" gradientUnits="userSpaceOnUse" x1="{a.real:.3f}" y1="{a.imag:.3f}" '
                         f'x2="{b.real:.3f}" y2="{b.imag:.3f}">{body}</linearGradient>')
        return f'url(#{i})'

    def radial(self, c, r, stops, focus):
        i = self._id()
        body = ''.join(f'<stop offset="{o}" stop-color="{s}"/>' for o, s in stops)
        self.defs.append(f'<radialGradient id="{i}" gradientUnits="userSpaceOnUse" cx="{c.real:.3f}" cy="{c.imag:.3f}" '
                         f'r="{r:.3f}" fx="{focus.real:.3f}" fy="{focus.imag:.3f}">{body}</radialGradient>')
        return f'url(#{i})'

    def blur(self, shapes, color, sigma, dx, dy, opacity, spread=0.0):
        i = self._id()
        self.defs.append(f'<filter id="{i}" filterUnits="userSpaceOnUse" x="-16" y="-16" width="96" height="96">'
                         f'<feGaussianBlur stdDeviation="{sigma}"/></filter>')
        grown = f' stroke="{color}" stroke-width="{spread}" stroke-linejoin="round"' if spread else ''
        body = ''.join(f'<path d="{path_data(s)}" fill="{color}"{grown}/>' for s in shapes)
        self.items.append(f'<g filter="url(#{i})" opacity="{opacity}" transform="translate({dx} {dy})">{body}</g>')

    def svg(self):
        return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs>' + ''.join(self.defs)
                + '</defs>' + ''.join(self.items) + '</svg>')


def spear(length, wide):
    """An arrowhead with its tip at the origin and its tail along +x.  Returns it, and its +y half."""
    side = (f'C{.28 * length} {.21 * wide} {.625 * length} {.59 * wide} {length} {wide} '
            f'C{.94 * length} {.67 * wide} {.856 * length} {.39 * wide} {.7625 * length} {.236 * wide}')
    whole = (f'M0 0 {side} L{.7625 * length} {-.236 * wide} C{.856 * length} {-.39 * wide} {.94 * length} {-.67 * wide} '
             f'{length} {-wide} C{.625 * length} {-.59 * wide} {.28 * length} {-.21 * wide} 0 0 Z')
    return parse(whole), parse(f'M0 0 {side} L{.7625 * length} 0 Z')


# ---- Two ways of printing -----------------------------------------------------------------------

class Marseille:
    """Woodcut and stencil, after the deck."""
    name = 'Marseille'
    woodcut = True

    def __init__(self, p):
        self.ink, self.paper, self.rouge, self.ochre = p['fg'], p['bg'], p['rouge'], p['ochre']
        self.slate, self.flesh, self.olive = p['slate'], p['flesh'], p['olive']
        self.sign = self.rouge

    def stand(self, art, parts, edge=1.2):
        """A soft shadow, and a paper edge so that it shows on dark windows."""
        art.blur(parts, self.ink, 1.25, 0.7, 1.5, 0.42, edge)
        for s in parts:
            art.stroke(s, self.paper, edge + 1.6)

    def plinth(self, art, shape):
        art.blur([shape], self.ink, 1.0, 0.4, 1.0, 0.4)
        art.stroke(shape, self.paper, 2.8)

    def body(self, art, shape, pigment=None, thin=1.0, heavy=2.1):
        art.fill(shape, self.paper)
        if pigment:
            art.fill(xf(shape, 0.45 + 0.35j), pigment)
        art.fill(contour(shape, thin * art.k, heavy * art.k), self.ink)

    def fused(self, art, shapes, pigment, weight=1.7):
        """Overlapping shapes under one outline, like a hand and its fingers."""
        for s in shapes:
            art.stroke(s, self.ink, 2 * weight * art.k)
            art.stroke(xf(s, 0.25 + 0.35j), self.ink, 2 * weight * art.k)
        for s in shapes:
            art.fill(s, pigment)

    def cut(self, art, points, width):
        art.fill(taper(points, width), self.ink)

    def comb(self, art, along, direction, length, count, width):
        if art.fine:
            art.fill(teeth(along, direction, length, count, width), self.ink)

    def head(self, art, tip, degrees, length, wide):
        """DEGREES is the way the tail runs from the tip.  The half turned from the light is combed."""
        self.body(art, xf(spear(length, wide)[0], tip, degrees), self.rouge)
        u = turn(degrees)
        ridge = [tip + u * .17 * length, tip + u * .75 * length]
        side = 1 if faces_light(u * 1j) < 0 else -1
        self.comb(art, ridge, u * turn(side * 142), lambda t: length * (.05 + .29 * t), max(4, int(length * .29)), 1.15)
        self.cut(art, ridge, swell(.25, 1.15, .9))

    def leaf(self, art, shape, tip, degrees):
        self.body(art, shape, self.rouge, .9, 1.7)
        u = turn(degrees)
        self.cut(art, [tip + u * 3, tip + u * 12], swell(.2, .9, .3))

    def shaft(self, art, shape):
        self.body(art, shape, self.ochre, .9, 1.5)

    def beam(self, art, shape):
        self.body(art, shape, self.ochre)

    def fin(self, art, shape):
        self.body(art, shape, self.slate, .9, 1.5)

    def petal(self, art, shape):
        self.body(art, shape, self.ochre, .85, 1.5)

    def collar(self, art, shape):
        self.body(art, shape, self.rouge, .7, 1.1)

    def boss(self, art, c, degrees, half):
        """A binding round a shaft."""
        shape = xf(parse(f'M-2.8 {-half} L2.8 {-half} L2.8 {half} L-2.8 {half} Z'), c, degrees)
        self.body(art, shape, self.rouge, .8, 1.2)
        if art.fine:
            self.cut(art, xf(line(f'M0 {-half + .2} L0 {half - .2}'), c, degrees), .85)

    def hub(self, art, c, r):
        self.body(art, circle(c, r), self.ochre, 1.0, 1.9)
        self.comb(art, [c + r * .85 * turn(a) for a in range(5, 115, 8)], turn(-110), 2.8, 9, .9)
        art.fill(circle(c, 1.3 * art.k), self.ink)

    def roundel(self, art, c, r):
        self.body(art, circle(c, r), self.paper, 1.1, 2.0)

    def sleeve(self, art, P, band, cuff, hem, degrees, sewn):
        """A cuff like the Bateleur's: ochre and hatched, with a red band at the wrist."""
        self.body(art, cuff, self.ochre, .9, 2.0)
        self.comb(art, P(line(hem)), turn(degrees - 90), lambda t: 2.4 + 1.4 * t, 12, 1.0)
        self.body(art, band, self.rouge, .9, 1.7)

    def skin(self, art, shapes, lines, nails, shade, light):
        self.fused(art, shapes, self.flesh)
        for points, width in lines + nails:
            self.cut(art, points, width)
        for args in shade:
            self.comb(art, *args)


class Arcana:
    """Gold leaf and violet enamel, after the wallpaper."""
    name = 'Arcana'
    woodcut = False

    def __init__(self, p):
        self.night, self.gold, self.violet = p['bg'], p['accent'], p['accent2']
        self.indigo, self.starlight = p['bg-high'], p['bright-white']
        self.deep_violet = to_hex(tuple(c * .42 for c in rgb(self.violet)))
        self.pale_violet = mix(self.violet, '#ffffff', .55)
        self.ink = self.night
        self.sign = self.tone(.95)

    def tone(self, t):
        """goldTone in the night wallpaper."""
        g = rgb(self.gold)
        if t < .5:
            return to_hex(tuple(c * .42 + c * .58 * t * 2 for c in g))
        hi = tuple(c + (w - c) * .72 for c, w in zip(g, (1.0, .97, .86)))
        return to_hex(tuple(c + (h - c) * (t * 2 - 1) for c, h in zip(g, hi)))

    def stand(self, art, parts, edge=1.05):
        """A faint warm air, a soft shadow, and a dark edge so that it shows on light windows."""
        art.blur(parts, self.gold, 2.4, 0, 0, 0.24, 1.6)
        art.blur(parts, '#000000', 1.3, 0.6, 1.4, 0.55, edge)
        for s in parts:
            art.stroke(s, self.night, edge * 2)

    def plinth(self, art, shape):
        art.blur([shape], '#000000', 1.0, 0.4, 1.0, 0.4)
        art.stroke(shape, self.night, 2.2)

    def sheen(self, art, a, b):
        return art.gradient(a, b, [(0, self.tone(1)), (.3, self.tone(.74)), (.7, self.tone(.44)), (1, self.tone(.26))])

    def enamel(self, art, a, b):
        return art.gradient(a, b, [(0, self.pale_violet), (.4, self.violet), (1, self.deep_violet)])

    def lit_gradient(self, art, shape, stops):
        """A gradient across SHAPE, from the corner nearest the light."""
        pts = shape[0]
        c = sum(pts[:-1]) / (len(pts) - 1)
        return art.gradient(max(pts, key=lambda p: faces_light(p - c)), min(pts, key=lambda p: faces_light(p - c)), stops)

    def body(self, art, shape, fill=None, thin=.75, heavy=1.25):
        art.fill(shape, fill or self.gold)
        art.fill(contour(shape, thin * art.k, heavy * art.k), self.night)

    def fused(self, art, shapes, fill, weight=.95):
        for s in shapes:
            art.stroke(s, self.night, 2 * weight * art.k)
        for s in shapes:
            art.fill(s, fill)

    def comb(self, art, along, direction, length, count, width):
        if art.fine:
            art.fill(teeth(along, direction, length, count, width), self.tone(.1))

    def head(self, art, tip, degrees, length, wide):
        whole, half = spear(length, wide)
        u = turn(degrees)
        art.fill(xf(half, tip, degrees), self.tone(.95 if faces_light(u * 1j) > 0 else .3))
        art.fill(xf(reflect_y(half), tip, degrees), self.tone(.95 if faces_light(-u * 1j) > 0 else .3))
        art.fill(contour(xf(whole, tip, degrees), .7 * art.k, 1.15 * art.k), self.night)

    def leaf(self, art, shape, tip, degrees):
        u = turn(degrees)
        c = tip + u * 7
        n = u * 1j if faces_light(u * 1j) > 0 else -u * 1j
        self.body(art, shape, art.gradient(c + n * 4, c - n * 4, [(0, self.tone(1)), (.49, self.tone(.8)), (.51, self.tone(.32)), (1, self.tone(.24))]))

    def shaft(self, art, shape):
        self.body(art, shape, self.lit_gradient(art, shape, [(0, self.tone(.92)), (.5, self.tone(.6)), (1, self.tone(.3))]), .7, 1.0)

    def beam(self, art, shape):
        self.body(art, shape, self.lit_gradient(art, shape, [(0, self.tone(1)), (.45, self.tone(.62)), (1, self.tone(.26))]))

    fin = beam
    petal = beam

    def collar(self, art, shape):
        self.body(art, shape, self.tone(.3), .7, 1.1)

    def boss(self, art, c, degrees, half):
        """A little enamel stud on a shaft."""
        r = half + 1.2
        art.fill(circle(c, r + .7 * art.k), self.night)
        art.fill(circle(c, r), self.enamel(art, c + r * LIGHT, c - r * LIGHT))
        art.fill(circle(c + r * .4 * LIGHT, r * .22), self.starlight)

    def hub(self, art, c, r):
        art.fill(circle(c, r), self.sheen(art, c + r * LIGHT, c - r * LIGHT))
        art.fill(contour(circle(c, r), .7 * art.k, 1.15 * art.k), self.night)
        inner = r * .62
        art.fill(circle(c, inner), art.radial(c, inner * 1.05, [(0, self.pale_violet), (.45, self.violet), (1, self.deep_violet)], c + inner * .35 * LIGHT))
        art.fill(circle(c + inner * .4 * LIGHT, inner * .18), self.starlight)

    def roundel(self, art, c, r):
        art.fill(circle(c, r), self.sheen(art, c + r * LIGHT, c - r * LIGHT))
        art.fill(contour(circle(c, r), .7 * art.k, 1.1 * art.k), self.night)
        art.fill(circle(c, r - 1.5 * art.k), art.gradient(c + r * LIGHT, c - r * LIGHT, [(0, self.indigo), (1, self.night)]))

    def sleeve(self, art, P, band, cuff, hem, degrees, sewn):
        """Violet enamel sewn with stars, and a band of gold at the wrist."""
        ends = P([complex(-10, 54), complex(27, 53)]) if degrees else [cuff[0][0], cuff[0][len(cuff[0]) // 2]]
        art.fill(cuff, self.enamel(art, *ends))
        if art.fine:
            for at in sewn:
                art.fill(star(at, 2.5, .45), self.tone(.98))
        art.fill(contour(cuff, .8 * art.k, 1.3 * art.k), self.night)
        art.fill(band, self.lit_gradient(art, band, [(0, self.tone(1)), (.5, self.tone(.7)), (1, self.tone(.3))]))
        art.fill(contour(band, .7 * art.k, 1.1 * art.k), self.night)

    def skin(self, art, shapes, lines, nails, shade, light):
        self.fused(art, shapes, self.sheen(art, 18 + 8j, 46 + 54j))
        for points, width in light:
            art.fill(taper(points, width), self.tone(1))
        for points, width in lines:
            art.fill(taper(points, width), self.tone(.04))
        for points, width in nails:
            art.fill(taper(points, width), self.tone(.14))
        for args in shade:
            self.comb(art, *args)


# ---- Resizing: local +x is the way the cursor points --------------------------------------------

def one_way(st, art, degrees, corner=False):
    """An arrow up against the edge or corner that it moves."""
    P = lambda s: xf(s, CENTER, degrees)
    if corner:
        stop = P(parse('M7.6 -17.5 L25.5 0 L7.6 17.5 L4.6 14.5 L19.5 0 L4.6 -14.5 Z'))
        tip = 15.5
    else:
        stop = P(parse('M19.8 -14 Q21.8 -13.2 24 -14 L24 14 Q21.8 13.2 19.8 14 Z'))
        tip = 17
    length, wide = 15, 9.4
    shaft = P(parse(f'M{tip - length * .8} -2.1 L-22 -1.9 L-22 1.9 L{tip - length * .8} 2.1 Z'))
    fins = [P(parse('M-14 1.9 L-20 8.2 L-27 8.2 L-23.4 1.9 Z')), P(parse('M-14 -1.9 L-20 -8.2 L-27 -8.2 L-23.4 -1.9 Z'))]
    st.stand(art, [stop, shaft, P(xf(spear(length, wide)[0], complex(tip), 180))] + fins)
    for fin in fins:
        st.fin(art, fin)
    st.shaft(art, shaft)
    st.beam(art, stop)
    st.head(art, P([complex(tip)])[0], degrees + 180, length, wide)


def two_way(st, art, degrees):
    """A whole axis."""
    P = lambda s: xf(s, CENTER, degrees)
    tip, length, wide = 27, 15, 9.8
    inner = tip - length * .8
    shaft = P(parse(f'M{-inner} -2.2 L{inner} -2.2 L{inner} 2.2 L{-inner} 2.2 Z'))
    head = spear(length, wide)[0]
    st.stand(art, [P(xf(head, complex(tip), 180)), P(xf(head, complex(-tip), 0)), shaft])
    st.shaft(art, shaft)
    for x, a in ((tip, 180), (-tip, 0)):
        st.head(art, P([complex(x)])[0], degrees + a, length, wide)
    st.boss(art, CENTER, degrees, 2.9)


def split(st, art, degrees):
    """Arrows either side of a divider."""
    P = lambda s: xf(s, CENTER, degrees)
    tip, length, wide = 27, 14, 9.6
    inner = tip - length * .8
    bars = [P(parse('M1.1 -16 L5.1 -16 L5.1 16 L1.1 16 Z')), P(parse('M-5.1 -16 L-1.1 -16 L-1.1 16 L-5.1 16 Z'))]
    shafts = [P(parse(f'M5.1 -2 L{inner} -2.1 L{inner} 2.1 L5.1 2 Z')), P(parse(f'M-5.1 -2 L{-inner} -2.1 L{-inner} 2.1 L-5.1 2 Z'))]
    head = spear(length, wide)[0]
    st.stand(art, bars + shafts + [P(xf(head, complex(tip), 180)), P(xf(head, complex(-tip), 0))])
    for s in shafts:
        st.shaft(art, s)
    for b in bars:
        st.beam(art, b)
    for x, a in ((tip, 180), (-tip, 0)):
        st.head(art, P([complex(x)])[0], degrees + a, length, wide)


# ---- Moving ------------------------------------------------------------------------------------

def cross_fleury(st, art):
    """X called this cursor `fleur`, so here it is: a cross with a fleur-de-lis on each arm."""
    quarters = (0, 90, 180, 270)
    spears, petals, collars, stems = [], [], [], []
    petal = parse('M2.6 -14.6 C5.4 -20.4 13.4 -21.8 13.6 -15.6 C13.7 -12.6 10.4 -11.6 9.4 -14 C7.6 -12.6 5.2 -12 3 -12 Z')
    for a in quarters:
        Q = lambda s: xf(s, CENTER, a)
        spears.append(Q(parse('M0 -27.4 C3.2 -24 5.2 -20.4 3.4 -15.6 L-3.4 -15.6 C-5.2 -20.4 -3.2 -24 0 -27.4 Z')))
        petals += [Q(petal), Q(reflect_x(petal))]
        collars.append(Q(parse('M-5 -15.6 L5 -15.6 L5 -12.6 L-5 -12.6 Z')))
        stems.append(Q(parse('M-2.4 -13 L2.4 -13 L2.4 -4 L-2.4 -4 Z')))
    hub = circle(CENTER, 6.6)
    st.stand(art, spears + petals + collars + stems + [hub])
    for s in stems:
        st.shaft(art, s)
    for s in petals:
        st.petal(art, s)
    for a, s in zip(quarters, spears):
        st.leaf(art, s, CENTER + turn(a - 90) * 27.4, a + 90)
    for s in collars:
        st.collar(art, s)
    st.hub(art, CENTER, 6.6)


def compass(st, art):
    """All directions at once: four points on a thin cross."""
    quarters = (0, 90, 180, 270)
    length, wide = 15, 9.4
    head = spear(length, wide)[0]
    heads = [xf(xf(head, complex(0, -27.4), 90), CENTER, a) for a in quarters]
    shafts = [xf(parse('M-1.9 -15.4 L1.9 -15.4 L1.9 -4 L-1.9 -4 Z'), CENTER, a) for a in quarters]
    hub = circle(CENTER, 6.2)
    st.stand(art, heads + shafts + [hub])
    for s in shafts:
        st.shaft(art, s)
    for a in quarters:
        st.head(art, xf([complex(0, -27.4)], CENTER, a)[0], a + 90, length, wide)
    st.hub(art, CENTER, 6.2)


# ---- Marks -------------------------------------------------------------------------------------

def cell(st, art):
    """A cross pattée, its arms flaring away from the middle."""
    arm = 'M-2.5 -3.4 C-2.8 -10 -4.6 -17 -9 -24 C-3.4 -22.4 3.4 -22.4 9 -24 C4.6 -17 2.8 -10 2.5 -3.4'
    quarters = (0, 90, 180, 270)
    points = []
    for a in quarters:
        points += xf(line(arm), CENTER, a)
    shape = [points + [points[0]]]
    st.stand(art, [shape])
    if st.woodcut:
        st.body(art, shape, st.ochre)
        for a in quarters:
            if faces_light(turn(a)) < 0:
                st.comb(art, xf(line('M3.4 -21.4 L2.4 -7'), CENTER, a), turn(a + 180), 2.6, 8, .95)
    else:
        for a in quarters:
            face = faces_light(turn(a - 90))
            art.fill(xf(parse(arm + ' Z'), CENTER, a), st.tone(.92 if face > .2 else .55 if face > -.2 else .3))
        art.fill(contour(shape, .7 * art.k, 1.2 * art.k), st.night)


def crosshair(st, art):
    quarters = (0, 90, 180, 270)
    arms = [xf(taper(line('M0 -4.4 L0 -26', 2), swell(1.2, 1.5, 2.6)), CENTER, a) for a in quarters]
    circlet = sector(CENTER, 12.3, 13.7, 0, 360, 72)
    ticks = [xf(taper(line('M0 -13 L0 -9.4', 2), swell(1.6, 1.0, .2)), CENTER, a) for a in (45, 135, 225, 315)]
    points = [star(CENTER + turn(a - 90) * 13, 2.8, .95) for a in quarters]
    st.stand(art, arms + [circlet], 1.0)
    if st.woodcut:
        for s in arms + ticks + [circlet]:
            art.fill(s, st.ink)
        for s in points:
            art.fill(s, st.rouge)
    else:
        for s in arms + ticks:
            art.fill(s, st.tone(.82))
        art.fill(circlet, st.tone(.62))
        for s in points:
            art.stroke(s, st.night, 1.0)
            art.fill(s, st.tone(1))


def text(st, art, degrees=0):
    P = lambda s: xf(s, CENTER, degrees)
    diamond = P([[-3.3j, 2.1 + 0j, 3.3j, -2.1 + 0j, -3.3j]])
    if st.woodcut:
        # A serifed I, cut with a gouge and touched with red as a rubricator would.
        stem = P(taper(line('M0 -19 L0 19', 4), lambda t: 2.9 - math.sin(t * math.pi) ** 2))
        serifs = [P(taper(line(f'M0 {y * 20.4} C{x * 2} {y * 20.6} {x * 6} {y * 21.2} {x * 10.6} {y * 22.8}'), swell(3, 1.9, .3)))
                  for y in (1, -1) for x in (1, -1)]
        parts = [stem] + serifs
        art.blur(parts, st.ink, .9, .4, 1.0, .35, 1.2)
        for s in parts:
            art.stroke(s, st.paper, 2.4)
        for s in parts:
            art.fill(s, st.ink)
        art.stroke(diamond, st.paper, 1.6)
        art.fill(diamond, st.rouge)
        art.fill(contour(diamond, .55, .85), st.ink)
    else:
        # A gilt rule between two stars.
        rule = P(parse('M-1.5 -19 L1.5 -19 L1.5 19 L-1.5 19 Z'))
        stars = [P(star(complex(0, y * 21), 7.4, 1.5)) for y in (1, -1)]
        parts = [rule] + stars + [diamond]
        art.blur(parts, st.gold, 1.8, 0, 0, .2, 1.2)
        art.blur(parts, '#000000', .9, .4, 1.0, .5, .9)
        for s in parts:
            art.stroke(s, st.night, 1.9)
        art.fill(rule, st.lit_gradient(art, rule, [(0, st.tone(1)), (.5, st.tone(.72)), (1, st.tone(.35))]))
        for s in stars:
            art.fill(s, st.tone(.95))
        art.fill(diamond, st.enamel(art, *P([-3.3j, 3.3j])))


def not_allowed(st, art, c=CENTER, outer=24, inner=17.2):
    across = [c + (inner + .6) * turn(-135), c + (inner + .6) * turn(45)]
    slash = bar(across[0], across[1], outer - inner - .6)
    hoop = ring(c, outer, inner)
    if st.woodcut:
        art.blur([hoop, slash], st.ink, 1.25, .7, 1.5, .42)
        for s in (circle(c, outer), circle(c, inner), slash):
            art.stroke(s, st.paper, 2.8)
        art.stroke(hoop, st.ink, 2.2 * art.k)
        art.stroke(slash, st.ink, 2.2 * art.k)
        art.fill(hoop, st.rouge, rule='evenodd')
        art.fill(slash, st.rouge)
        st.comb(art, [c + (outer - .2) * turn(a) for a in range(0, 110, 6)], turn(-125), 3.2, 14, 1.0)
        st.comb(art, [c + (inner + .2) * turn(a) for a in range(180, 280, 6)], turn(70), 2.4, 10, .9)
    else:
        # An eclipse: the dark disc, its corona, and a bar of gold across it.
        corona = []
        for k in range(16):
            a = k * 22.5
            reach = 3.4 if k % 2 == 0 else 1.9
            corona.append([[c + turn(a - 4.4) * (outer - .4), c + turn(a) * (outer + reach), c + turn(a + 4.4) * (outer - .4), c + turn(a - 4.4) * (outer - .4)]])
        disc = circle(c, outer)
        art.blur(corona + [disc], st.gold, 2.4, 0, 0, .3, 1.0)
        art.blur([disc], '#000000', 1.3, .6, 1.4, .55, 1.0)
        for s in corona:
            art.stroke(s, st.night, 1.2)
        for s in corona:
            art.fill(s, st.tone(.82))
        art.fill(disc, st.night)
        art.fill(hoop, st.sheen(art, c + outer * LIGHT, c - outer * LIGHT), rule='evenodd')
        art.fill(contour(disc, .7, 1.0), st.night)
        art.fill(contour(circle(c, inner), .6, .9, hole=True), st.night)
        art.fill(circle(c, inner - .4), art.gradient(c + inner * LIGHT, c - inner * LIGHT, [(0, st.indigo), (1, st.night)]), opacity=.82)
        art.stroke(slash, st.night, 1.8)
        st.beam(art, slash)


def lens(st, art, plus):
    c = LENS
    outer, inner = 21, 15.6
    handle = capsule(c + 20.4 * turn(45), c + 39.5 * turn(45), 3.5, 3.1)
    hoop = ring(c, outer, inner)
    st.stand(art, [circle(c, outer), handle])
    glint = [c + 11.4 * turn(a) for a in range(-160, -100, 4)]
    if st.woodcut:
        art.fill(circle(c, inner), st.paper, opacity=.72)
        st.body(art, handle, st.rouge)
        for x in (26.5, 29.7):
            st.cut(art, [c + x * turn(45) + 3.4 * turn(135), c + x * turn(45) - 3.4 * turn(135)], .95 * art.k)
        art.fill(xf(hoop, .45 + .35j), st.ochre, rule='evenodd')
        art.fill(contour(circle(c, outer), art.k, 2.1 * art.k), st.ink)
        art.fill(contour(circle(c, inner), .9 * art.k, 1.7 * art.k, hole=True), st.ink)
        st.comb(art, [c + (outer - .4) * turn(a) for a in range(0, 100, 5)], turn(-125), 3.0, 14, 1.0)
        st.cut(art, glint, swell(.3, 1.6, .3))
        mark = st.ink
    else:
        art.fill(circle(c, inner), art.gradient(c + inner * LIGHT, c - inner * LIGHT, [(0, st.deep_violet), (1, st.night)]), opacity=.78)
        grip = c + 22 * turn(45)
        st.body(art, handle, st.enamel(art, grip + 3 * LIGHT, grip - 3 * LIGHT))
        art.fill(hoop, st.sheen(art, c + outer * LIGHT, c - outer * LIGHT), rule='evenodd')
        art.fill(contour(circle(c, outer), .7, 1.1), st.night)
        art.fill(contour(circle(c, inner), .6, .9, hole=True), st.night)
        art.fill(taper(glint, swell(.3, 1.5, .3)), st.tone(1))
        mark = st.tone(.92)
    art.fill(bar(c - 8.6, c + 8.6, 3.3), mark)
    if plus:
        art.fill(bar(c - 8.6j, c + 8.6j, 3.3), mark)


# ---- Hands -------------------------------------------------------------------------------------

POINTING = ('M-3.7 5 C-3.7 1.6 -2 0 0 0 C2 0 3.7 1.6 3.7 5 C3.7 9 4.3 11 4.1 14 C4 17 4.3 20 4.4 23 '
            'C5.2 20.6 8.6 19.8 10.7 21.6 C11.7 22.5 12.1 23.8 12.2 25.4 '
            'C13.3 23.2 16.6 23.2 18.2 25.1 C19 26.1 19.3 27.4 19.3 29 '
            'C20.3 27.7 22.9 28.1 23.9 30 C24.6 31.6 24.8 33.4 24.8 35.4 '
            'C24.8 40 24 43.6 22.4 47.4 L-6.6 49.2 '
            'C-8.2 45.6 -9.8 42.6 -11.8 39.6 '
            'C-13.4 37 -15.6 34.6 -15.4 31.6 C-15.2 29.2 -12.4 29 -11 30.8 '
            'C-9.4 32.8 -7.2 34.8 -4.6 35.6 '
            'C-4.3 30 -4.2 24 -4.1 19 C-4 16 -4.3 14 -4.1 12 C-3.9 9 -3.7 8 -3.7 5 Z')


def pointer(st, art, tip=HAND_TIP, degrees=-33):
    """The printer's manicule.  Its fingertip is the hotspot."""
    P = lambda s: xf(s, tip, degrees)
    body = P(parse(POINTING))
    band = P(parse('M-8.4 48.2 C0 49 12 48.2 23.4 46 L25 50.8 C13 53 0 54 -10.4 53.2 Z'))
    cuff = P(parse('M-10.2 52.6 C0 53.8 13 52.8 24.8 50.2 L27.2 55.6 C14 58.2 -1 59.2 -12.4 58.2 Z'))
    st.stand(art, [body, band, cuff])
    sewn = P([complex(-6.4 + k * 9.6, 55.4 - .22 * k * k) for k in range(4)])
    st.sleeve(art, P, band, cuff, 'M-11 57.8 C2 58.8 15 57.8 26.6 55.2', degrees, sewn)
    lines = [(P(line(p)), w) for p, w in (
        ('M4.4 22.8 C4.7 26 4.8 30 4.4 35', swell(1.5, 1.2, .25)),
        ('M12.2 25.2 C12.5 28 12.5 32 12.1 36.4', swell(1.4, 1.15, .25)),
        ('M19.3 28.8 C19.6 31 19.5 34 19.1 37.6', swell(1.3, 1.05, .25)),
        ('M-2.6 13.6 Q0 14.6 2.8 13.6', swell(.25, 1.05, .25)),
        ('M-2.3 15.6 Q0 16.4 2.6 15.6', swell(.2, .75, .2)),
        ('M-11 30.8 C-8.6 34 -6.8 38.4 -6.4 42', swell(.25, 1, .2)))]
    nails = [(P(line(p)), w) for p, w in (
        ('M-2.1 5.8 Q0 7.1 2.1 5.8', swell(.25, .85, .25)),
        ('M-2.2 5.6 C-2.4 2.4 2.4 2.4 2.2 5.6', swell(.3, .7, .3)),
        ('M-14.2 31.3 C-13.8 30.2 -12.7 30.1 -12 31.2', swell(.25, .75, .25)))]
    shade = [(P(line('M24.4 35.4 C24.5 40 23.6 43.6 22 47')), turn(degrees + 197), lambda t: 2.6 + 3.6 * math.sin(t * math.pi), 7, 1.0),
             (P(line('M-5 48.4 C4 48.2 14 47.4 21.6 46.4')), turn(degrees - 82), lambda t: 2.0 + 2.4 * t, 11, .85)]
    if st.woodcut:
        shade.append((P(line('M3.9 7 C4.2 11 4 17 4.3 21.6')), turn(degrees + 180), 2.2, 7, .8))
        st.body(art, body, st.flesh)
        for points, width in lines + nails:
            st.cut(art, points, width)
        for args in shade:
            st.comb(art, *args)
    else:
        art.fill(body, st.sheen(art, tip + 2 * turn(-125), tip + 56 * turn(55)))
        for p, w in (('M-2.5 6 C-2.6 12 -2.8 22 -3.1 32', swell(.3, 1.4, .1)),
                     ('M6.5 23.6 C7.6 23 9 23.3 9.8 24.2', swell(.1, 1.1, .1)),
                     ('M14.2 26.4 C15.2 25.9 16.3 26.2 17 27', swell(.1, 1.0, .1)),
                     ('M21 31 C21.6 30.7 22.3 31 22.8 31.7', swell(.1, .9, .1))):
            art.fill(taper(P(line(p)), w), st.tone(1))
        art.fill(contour(body, .8 * art.k, 1.5 * art.k), st.night)
        for points, width in lines:
            art.fill(taper(points, width), st.tone(.04))
        art.fill(taper(*nails[0]), st.tone(.12))
        for args in shade:
            st.comb(art, *args)


def upright_sleeve(y, left, right):
    """The same cuff, for a hand held straight up."""
    m = (left + right) / 2
    band = parse(f'M{left - 1} {y} Q{m} {y + 2.2} {right + 1} {y} L{right + 2.2} {y + 5} Q{m} {y + 7.4} {left - 2.2} {y + 5} Z')
    cuff = parse(f'M{left - 2} {y + 4.6} Q{m} {y + 7} {right + 2} {y + 4.6} L{right + 3.2} {y + 9} Q{m} {y + 11.2} {left - 3.2} {y + 9} Z')
    return band, cuff


def paint_upright_sleeve(st, art, band, cuff, y, left, right):
    m = (left + right) / 2
    hem = f'M{left - 2.4} {y + 9.4} Q{m} {y + 11.6} {right + 2.4} {y + 9.4}'
    sewn = [complex(m + k * 10, y + 7.6 - abs(k) * .5) for k in (-1, 0, 1)]
    st.sleeve(art, lambda s: s, band, cuff, hem, 0, sewn)


def grab(st, art):
    """Open, ready to take hold."""
    fingers = [(23.5, 30, 20.5, 11.5, 3.5, 3.1), (30, 28.5, 28.8, 7.6, 3.6, 3.2),
               (36.5, 29, 37.2, 9.5, 3.5, 3.1), (42.6, 31.5, 45.2, 16.5, 3.2, 2.8)]
    palm = parse('M19.4 30 C24 27.6 42 27.6 46 30.4 C47 36 47 41 45.6 46 C45 47.8 44.4 49.2 44 50.6 L22.6 50.6 C21.6 48 20.4 45.4 19.8 42.6 Z')
    shapes = [capsule(24 + 45j, 9.8 + 30.6j, 4.2, 3.2)]
    shapes += [capsule(complex(x, y), complex(a, b), r0, r1) for x, y, a, b, r0, r1 in fingers]
    shapes.append(palm)
    band, cuff = upright_sleeve(49, 22.4, 44.2)
    st.stand(art, shapes + [band, cuff])
    paint_upright_sleeve(st, art, band, cuff, 49, 22.4, 44.2)
    lines = [(line('M27 30 C27 32 27.1 34 26.9 37'), swell(1.3, 1, .2)),
             (line('M33.4 29.5 C33.5 32 33.5 34 33.3 37.4'), swell(1.3, 1, .2)),
             (line('M39.8 30.5 C39.8 32.5 39.8 34.5 39.5 37'), swell(1.2, .9, .2)),
             (line('M19.8 38.6 C20.6 41 21.6 43 23.6 45'), swell(1.2, .9, .2))]
    nails = []
    for x, y, a, b, r0, r1 in fingers:
        base, end = complex(x, y), complex(a, b)
        u = (end - base) / abs(end - base)
        for along, width in ((.42, .95), (.72, .8)):
            m = base + (end - base) * along
            lines.append(([m - u * 1j * r0 * .6, m - u * .3, m + u * 1j * r0 * .6], swell(.2, width, .2)))
        nails.append(([end - u * 1j * r1 * .62 + u * .3, end + u * 1.5, end + u * 1j * r1 * .62 + u * .3], swell(.2, .7, .2)))
    shade = [(line('M46.4 34 C46.6 38 46 43 44.8 47'), turn(196), lambda t: 2.4 + 3 * math.sin(t * math.pi), 7, 1.0),
             (line('M24 47.6 C30 48.2 37 48.2 43 47.6'), -1j, lambda t: 1.6 + 2.6 * t, 9, .9)]
    light = [(line('M21.4 28 L19.6 13.4'), swell(.2, 1.1, .1)), (line('M28.6 26.5 L27.4 9'), swell(.2, 1.1, .1)),
             (line('M35.6 26.5 L35.9 11'), swell(.2, 1.1, .1)), (line('M42 28 L43.9 18'), swell(.2, 1, .1)),
             (line('M21 42.5 L10.2 29.8'), swell(.2, 1, .1))]
    st.skin(art, shapes, lines, nails, shade, light)


def grabbing(st, art):
    """Closed on what it's holding."""
    knuckles = [(23.5, 30, 22.5, 22, 4.0, 4.0), (30.6, 28, 30.2, 19.4, 4.1, 4.1),
                (37.8, 28.5, 37.8, 20.6, 4.0, 4.0), (44.4, 31, 44.8, 24.6, 3.7, 3.7)]
    palm = parse('M18.6 28 C24 24.6 44 25 48.2 28 C49.2 34 49 40 47.4 45 C46.8 47 46.2 48.6 45.8 50 L22.6 50 C21 46.6 19.6 43 18.8 39 Z')
    shapes = [capsule(25 + 42j, 15.4 + 28.4j, 4.4, 3.6)]
    shapes += [capsule(complex(x, y), complex(a, b), r0, r1) for x, y, a, b, r0, r1 in knuckles]
    shapes.append(palm)
    band, cuff = upright_sleeve(48.4, 22.4, 45.8)
    st.stand(art, shapes + [band, cuff])
    paint_upright_sleeve(st, art, band, cuff, 48.4, 22.4, 45.8)
    lines = [(line('M26.9 21.4 C27 24 27 28 26.8 31'), swell(1.4, 1.1, .2)),
             (line('M34.1 20.6 C34.2 24 34.2 28 34 31'), swell(1.4, 1.1, .2)),
             (line('M41.4 22 C41.5 25 41.4 28 41.2 31'), swell(1.3, 1, .2)),
             (line('M19.8 26 C21 32 21.6 37 24.6 41'), swell(.5, 1, .2))]
    for a, b in ((20.4, 26.2), (27.6, 33.6), (34.8, 40.8), (42, 47.4)):
        lines.append((line(f'M{a} 32.8 Q{(a + b) / 2} 35 {b} 32.8'), swell(.2, .95, .2)))
    shade = [(line('M48.6 33 C48.8 38 48 42 46.8 46.4'), turn(196), lambda t: 2.4 + 3 * math.sin(t * math.pi), 7, 1.0),
             (line('M24 47.4 C30 48 37 48 44.8 47.4'), -1j, lambda t: 1.6 + 2.6 * t, 10, .9)]
    light = [(line('M20.6 21.6 C21.2 20 22.6 19.4 23.8 19.6'), swell(.2, 1.1, .1)),
             (line('M28 18.6 C29 17 30.8 16.8 32 17.2'), swell(.2, 1.1, .1)),
             (line('M35.6 19.8 C36.4 18.4 38.2 18.2 39.4 18.8'), swell(.2, 1, .1)),
             (line('M42.6 23.4 C43.4 22 44.8 21.9 45.8 22.4'), swell(.2, .9, .1))]
    st.skin(art, shapes, lines, [], shade, light)


# ---- The arrow and the star --------------------------------------------------------------------

def cupids_arrow(st, art, tip=TIP, degrees=58):
    """The arrow out of L'Amoureux, its head as big as a pointer's has to be."""
    P = lambda s: xf(s, tip, degrees)
    length, wide = 32, 14.4
    shaft = P(parse('M22 -2.3 L52 -2.1 L52 2.1 L22 2.3 Z'))
    fins = [P(parse('M41 2.2 L47 8.8 C51 9.2 56 9.2 60.5 8.8 L55.5 2.2 Z')),
            P(parse('M41 -2.2 L47 -8.8 C51 -9.2 56 -9.2 60.5 -8.8 L55.5 -2.2 Z'))]
    binding = P(parse('M23.6 -3.5 L30 -3.1 L30 3.1 L23.6 3.5 Z'))
    st.stand(art, [P(spear(length, wide)[0]), shaft, binding] + fins)
    u = turn(degrees)
    for fin, side in zip(fins, (1, -1)):
        st.fin(art, fin)
        st.comb(art, P(line(f'M43 {side * 2.4} L55 {side * 2.4}')), u * turn(side * 62), 6.4, 6, 1.0)
    st.shaft(art, shaft)
    st.cut(art, P(line('M52.4 -2.4 L55 0 L52.4 2.4')), 1.2 * art.k)
    st.head(art, tip, degrees, length, wide)
    st.body(art, binding, st.rouge, .8, 1.2)
    if art.fine:
        for x in (26, 28):
            st.cut(art, P(line(f'M{x} -3.3 L{x} 3.3')), .85)


def ray(st, art, c, degrees, length, base, lit=.95, shade=.36):
    """One point of a rose: two flat facets meeting on a ridge."""
    u = turn(degrees)
    for side in (-1, 1):
        art.fill([[c, c + u * length, c + u * turn(side * 45) * base, c]], st.tone(lit if faces_light(u * 1j * side) > 0 else shade))


def guiding_star(st, art, tip=TIP, alone=True):
    """The rose from the wallpaper's hub, with its long point for the arrow."""
    c = tip + 37 * turn(46)
    major = [(-134, 37, 7.6), (-44, 23, 6.4), (46, 24, 6.6), (136, 23, 6.4)]
    minor = [(-89, 13, 4.6), (1, 13, 4.6), (91, 13, 4.6), (181, 13, 4.6)]

    def rose(rays):
        points = []
        for a, r, s in rays:
            points += [c + turn(a - 45) * s, c + turn(a) * r]
        return [points + [points[0]]]

    st.stand(art, [rose(major), rose(minor), circle(c, 7)])
    for a, r, s in minor:
        ray(st, art, c, a, r, s, .72, .2)
    for a, r, s in major:
        ray(st, art, c, a, r, s)
    if art.fine:
        art.fill(taper([c + turn(-134) * 7, c + turn(-134) * 35], swell(.75, .4, .05)), st.tone(1))
    art.fill(circle(c, 6.9), st.night)
    st.hub(art, c, 6.1)
    if art.fine and alone:
        for at, r in ((c + 24 * turn(-92), 4.2), (c + 24.5 * turn(2), 3.6)):
            art.fill(star(at, r, r * .24), st.tone(.92))


def default(st, art, alone=True):
    if st.woodcut:
        cupids_arrow(st, art)
    else:
        guiding_star(st, art, alone=alone)


# ---- A pointer with something to say -----------------------------------------------------------

def badge_spot(st):
    return (49 + 37j) if st.woodcut else (48.5 + 48.5j)


BADGE = 11.2


def question(st, art, c):
    art.fill(taper(xf(line('M-4 -3.4 C-4 -8 4.2 -8.2 4.2 -3 C4.2 .2 0 .2 0 3.4'), c), swell(1.6, 2.8, 2.4)), st.sign)
    art.fill(circle(c + 6.6j, 1.8), st.sign)


def plus(st, art, c):
    art.fill(bar(c - 6.2, c + 6.2, 3.2), st.sign)
    art.fill(bar(c - 6.2j, c + 6.2j, 3.2), st.sign)


def curved_arrow(st, art, c):
    art.fill(taper(xf(line('M-5.6 5.6 C-5.6 -.6 -2 -2.6 1.8 -2.6'), c), swell(2.6, 2.6, 2.4)), st.sign)
    art.fill(xf([[0j, -6.2 + 4.6j, -6.2 - 4.6j, 0j]], c + 6.6 - 2.6j), st.sign)


def badged(st, art, sign):
    default(st, art, alone=False)
    c = badge_spot(st)
    st.plinth(art, circle(c, BADGE))
    st.roundel(art, c, BADGE)
    sign(st, art, c)


def context_menu(st, art):
    """A card, ruled like a menu."""
    default(st, art, alone=False)
    c = badge_spot(st)
    card = xf(parse('M-7 -9.6 L7 -9.6 L7 9.6 L-7 9.6 Z'), c, 7)
    rows = [xf(line(f'M-4.2 {y} L4.2 {y}'), c, 7) for y in (-5, 0, 5)]
    st.plinth(art, card)
    if st.woodcut:
        st.body(art, card, st.paper, .9, 1.6)
        for k, row in enumerate(rows):
            art.fill(taper(row, 1.7), st.rouge if k == 0 else st.ink)
    else:
        st.body(art, card, art.gradient(c + BADGE * LIGHT, c - BADGE * LIGHT, [(0, st.indigo), (1, st.night)]))
        art.stroke(card, st.tone(.8), 1.1)
        for row in rows:
            art.fill(taper(row, 1.5), st.tone(.9))


def no_drop(st, art):
    default(st, art, alone=False)
    c = badge_spot(st)
    r = BADGE
    st.plinth(art, circle(c, r))
    hoop = ring(c, r, r * .66)
    slash = bar(c + r * .68 * turn(-135), c + r * .68 * turn(45), r * .34)
    if st.woodcut:
        art.fill(circle(c, r), st.paper)
        art.stroke(circle(c, r), st.ink, 1.5 * art.k)
        art.stroke(circle(c, r * .66), st.ink, 1.3 * art.k)
        art.stroke(slash, st.ink, 1.3 * art.k)
        art.fill(hoop, st.rouge, rule='evenodd')
        art.fill(slash, st.rouge)
    else:
        art.fill(circle(c, r), st.night)
        art.fill(hoop, st.sheen(art, c + r * LIGHT, c - r * LIGHT), rule='evenodd')
        art.stroke(slash, st.night, 1.3)
        art.fill(slash, st.tone(.95))


def progress(st, art, a):
    """Busy, but it can still be clicked, so the pointer stays and its hotspot with it."""
    default(st, art, alone=False)
    c = badge_spot(st)
    r = BADGE
    st.plinth(art, circle(c, r))
    if st.woodcut:
        art.fill(circle(c, r), st.paper)
        art.fill(xf(ring(c, r, r * .68), .3 + .25j), st.ochre, rule='evenodd')
        art.fill(xf(sector(c, r * .68, r, a, a + 120, 12), .3 + .25j), st.rouge)
        art.fill(contour(circle(c, r), art.k, 1.8 * art.k), st.ink)
        art.fill(contour(circle(c, r * .68), .7 * art.k, 1.1 * art.k, hole=True), st.ink)
        for k in range(6):
            u = turn(a + k * 60)
            art.fill(taper([c + u * r * .2, c + u * r * .7], 1.9 * art.k), st.slate if k % 2 else st.ink)
        art.fill(circle(c, r * .3), st.ink)
        art.fill(circle(c, r * .17), st.ochre)
    else:
        art.fill(circle(c, r), st.sheen(art, c + r * LIGHT, c - r * LIGHT))
        art.fill(contour(circle(c, r), .7 * art.k, 1.1 * art.k), st.night)
        inner = r - 1.8 * art.k
        art.fill(circle(c, inner), st.night)
        moon(st, art, c, inner - .8, a, maria=False)


# ---- Waiting -----------------------------------------------------------------------------------

def la_roue(st, art, a):
    """Card X: a wheel with turned spokes, on its trestle, with a crank, and a crown over it.
    The wheel goes round, but the light and the hatching on it stay where they are."""
    c = 32 + 34j
    outer, inner = 21.6, 16.4
    legs = [parse('M15.6 40 L20.4 40 L13.6 56.4 L8.2 56.4 Z'), parse('M43.6 40 L48.4 40 L55.8 56.4 L50.4 56.4 Z')]
    foot = parse('M6.8 56 L57.2 56 L58.2 59.6 L5.8 59.6 Z')
    crown = parse('M25 12.6 L22.4 5.2 L27.8 8.4 L32 3.7 L36.2 8.4 L41.6 5.2 L39 12.6 Q32 14 25 12.6 Z')
    st.stand(art, legs + [foot, circle(c, outer), crown])
    for leg in legs:
        st.body(art, leg, st.flesh, .9, 1.8)
    st.comb(art, line('M20 41 L13.5 55.6'), turn(180), 2.4, 7, .9)
    st.comb(art, line('M48 41 L55.2 55.6'), turn(180), 2.4, 7, .9)
    st.body(art, foot, st.slate, .9, 1.8)
    # The rim, stencilled ochre with a third of it red.
    art.fill(circle(c, inner), st.paper)
    art.fill(xf(ring(c, outer, inner), .4 + .3j), st.ochre, rule='evenodd')
    art.fill(xf(sector(c, inner, outer, a - 60, a + 60), .4 + .3j), st.rouge)
    # Turned spokes, slate and olive by turns, each with a red collar.
    for k in range(6):
        u = turn(a + k * 60)
        n = u * 1j

        def turned(root, belly, end):
            pts = [c + u * 5.4 + n * root, c + u * 11.6 + n * belly, c + u * 16.6 + n * end,
                   c + u * 16.6 - n * end, c + u * 11.6 - n * belly, c + u * 5.4 - n * root]
            return [pts + [pts[0]]]

        art.fill(turned(1.5, 2.5, 2.2), st.ink)
        art.fill(turned(.7, 1.65, 1.4), st.slate if k % 2 else st.olive)
        art.fill(circle(c + u * 9.2, 2.6), st.ink)
        art.fill(circle(c + u * 9.2, 1.6), st.rouge)
    art.fill(contour(circle(c, outer), art.k, 2.1 * art.k), st.ink)
    art.fill(contour(circle(c, inner), .8 * art.k, 1.5 * art.k, hole=True), st.ink)
    for k in range(12):
        u = turn(a + k * 30)
        art.fill(taper([c + u * (inner + .4), c + u * (outer - .4)], .9 * art.k), st.ink)
    st.comb(art, [c + (outer - .4) * turn(x) for x in range(5, 125, 4)], turn(-125), 2.6, 26, .85)
    st.body(art, circle(c, 6), st.ochre, .9, 1.8)
    # The crank goes round with it.
    v = turn(a + 20)
    arm = taper([c, c + v * 11], swell(2.6, 2.2, 2.2))
    art.stroke(arm, st.ink, 1.5)
    art.fill(circle(c + v * 11.2, 2.9), st.ink)
    art.fill(arm, st.rouge)
    art.fill(circle(c + v * 11.2, 2), st.rouge)
    art.fill(circle(c, 1.5), st.ink)
    # The crown doesn't move at all.
    st.body(art, crown, st.ochre, .9, 1.7)
    for at, s in ((22.4 + 5.2j, 1.4), (32 + 3.7j, 1.6), (41.6 + 5.2j, 1.4)):
        art.fill(circle(at, s + .7), st.ink)
        art.fill(circle(at, s), st.rouge)
    if art.fine:
        st.cut(art, line('M26.2 10.6 Q32 11.7 37.8 10.6'), .9)


def moon(st, art, c, r, a, maria=True, tilt=-22):
    """The moon, A degrees through its month, with earthshine on its dark side."""
    phi = math.radians(a) % TAU
    w = turn(tilt)
    n = 32
    ys = [-r + 2 * r * k / n for k in range(n + 1)]
    half = [math.sqrt(max(r * r - y * y, 0)) for y in ys]
    side, across = (1, math.cos(phi)) if phi <= math.pi else (-1, -math.cos(phi))
    limb = [complex(side * h, y) for h, y in zip(half, ys)]
    terminator = [complex(across * h, y) for h, y in zip(half, ys)]
    lit = [[c + w * p for p in limb + terminator[::-1]] + [c + w * limb[0]]]
    art.fill(circle(c, r), art.gradient(c + r * LIGHT, c - r * LIGHT, [(0, st.indigo), (1, mix(st.indigo, st.night, .5))]))
    art.fill(lit, art.radial(c + r * .3 * LIGHT, r * 1.25, [(0, mix(st.tone(1), '#ffffff', .25)), (.65, st.tone(.82)), (1, st.tone(.55))], c + r * .3 * LIGHT))
    if maria and art.fine:
        clip = art.clip(lit)
        for at, rx, ry, degrees in ((-.30 - .34j, .30, .23, 20), (.20 - .42j, .24, .18, -15), (.34 + .02j, .27, .2, 30),
                                    (-.12 + .12j, .36, .25, 0), (-.46 + .34j, .2, .17, 40), (.16 + .56j, .17, .12, 10)):
            art.fill(ellipse(c + w * at * r, rx * r, ry * r, tilt + degrees), st.tone(.3), opacity=.5, clip=clip)
    art.fill(contour(circle(c, r), .45 * art.k, .7 * art.k), st.night, opacity=.75)


def la_lune(st, art, a):
    """A limb of gold that creeps round, a star that races round, and the moon's month."""
    c = CENTER
    outer, inner = 27, 23
    disc = circle(c, outer)
    st.stand(art, [disc])
    art.fill(disc, st.sheen(art, c + outer * LIGHT, c - outer * LIGHT))
    art.fill(circle(c, inner), art.gradient(c + inner * LIGHT, c - inner * LIGHT, [(0, st.indigo), (1, st.night)]))
    art.fill(contour(disc, .6 * art.k, art.k), st.night)
    art.fill(contour(circle(c, inner), .6 * art.k, .9 * art.k, hole=True), st.night)
    # A twelfth of a turn in a loop brings the marks back to where they began.
    for k in range(36):
        u = turn(a / 12 + k * 10)
        big = k % 3 == 0
        art.fill(taper([c + u * (outer - .5), c + u * (outer - (3.2 if big else 2))], (1.15 if big else .7) * art.k), st.night)
    if art.fine:
        for k, (reach, size, rate) in enumerate(((20, 1.5, 2), (21, 1.1, 3), (19.6, 1.3, 1), (20.6, 1.0, 2), (19.8, 1.4, 3), (20.8, 1.1, 1))):
            twinkle = .72 + .28 * math.sin(math.radians(a * rate + k * 67))
            art.fill(star(c + reach * turn(30 + k * 60), size * 1.5 * twinkle, size * .3 * twinkle), st.tone(.85))
    # The star, and the wake it leaves.
    for k in range(5, 0, -1):
        art.fill(circle(c + 19.4 * turn(a * 2 - 90 - k * 11), 1.35 - k * .16), st.tone(.92), opacity=round(.55 - k * .09, 3))
    at = c + 19.4 * turn(a * 2 - 90)
    art.stroke(star(at, 4.4, 1.0), st.night, 1.0)
    art.fill(star(at, 4.4, 1.0), st.starlight)
    moon(st, art, c, 13.6, a)


def wait(st, art, a):
    (la_roue if st.woodcut else la_lune)(st, art, a)


# ---- The table ---------------------------------------------------------------------------------
# Name: drawing, hotspot, other names.  Compositors ask for the CSS names and old toolkits for the
# rest, including the hashes that Qt and old GTK used to ask X for.

def at_angle(draw, degrees, *rest):
    return lambda st, art: draw(st, art, degrees, *rest)


CURSORS = {
    'default': (default, TIP, 'arrow left_ptr top_left_arrow'),
    'pointer': (pointer, HAND_TIP, 'hand hand1 hand2 pointing_hand 9d800788f1b08800ae810202380a0822 e29285e634086352946a0e7090d73106'),
    'text': (text, CENTER, 'ibeam xterm'),
    'vertical-text': (at_angle(text, 90), CENTER, ''),
    'wait': (wait, CENTER, 'watch'),
    'progress': (progress, TIP, 'half-busy left_ptr_watch 00000000000000020006000e7e9ffc3f 08e8e1c95fe2fc01f976f1e063a24ccd 3ecb610c1bf2410f44200f48c40d3599'),
    'help': (lambda st, art: badged(st, art, question), TIP, 'dnd-ask left_ptr_help question_arrow whats_this 5c6cd98b3f3ebcb1f9c7f1c204630408 d9ce0ab605698f320427677b458ad60b'),
    'context-menu': (context_menu, TIP, ''),
    'alias': (lambda st, art: badged(st, art, curved_arrow), TIP, 'dnd-link link 3085a0e285430894940527032f8b26df 640fb0e74195791501fd1ed57b41487f a2a266d0498c3104214a47bd64ab0fc8'),
    'copy': (lambda st, art: badged(st, art, plus), TIP, 'dnd-copy 1081e37283d90000800003c07f3ef6bf 6407b0e94181790501fd1e167b474872 b66166c04f8c3109214a4fbd64a50fc8'),
    'no-drop': (no_drop, TIP, 'dnd-no-drop dnd-none forbidden'),
    'not-allowed': (not_allowed, CENTER, 'circle crossed_circle 03b6e0fcb3499374a867c041f52298f0 X_cursor pirate'),
    'cell': (cell, CENTER, 'plus'),
    'crosshair': (crosshair, CENTER, 'cross cross_reverse diamond_cross tcross'),
    'move': (cross_fleury, CENTER, 'dnd-move fleur size_all 4498f0e0c1937ffe01fd06f973665830 9081237383d90e509aa00f00170e968f'),
    'all-scroll': (compass, CENTER, 'all-resize'),
    'grab': (grab, 32 + 28j, 'openhand'),
    'grabbing': (grabbing, 32 + 30j, 'closedhand fcf21c00b30f7e3f83fe0dfd12e71cff'),
    'zoom-in': (lambda st, art: lens(st, art, True), LENS, ''),
    'zoom-out': (lambda st, art: lens(st, art, False), LENS, ''),
    'ew-resize': (at_angle(two_way, 0), CENTER, 'h_double_arrow sb_h_double_arrow size_hor 028006030e0e7ebffc7f7070c0600140'),
    'ns-resize': (at_angle(two_way, 90), CENTER, 'v_double_arrow sb_v_double_arrow size_ver 00008160000006810000408080010102'),
    'nesw-resize': (at_angle(two_way, -45), CENTER, 'fd_double_arrow size_bdiag fcf1c3c7cd4491d801f1e1c78f100000'),
    'nwse-resize': (at_angle(two_way, 45), CENTER, 'bd_double_arrow size_fdiag c7088f0f3e6c8088236ef8e1e3e70000'),
    'col-resize': (at_angle(split, 0), CENTER, 'split_h 14fef782d02440884392942c11205230'),
    'row-resize': (at_angle(split, 90), CENTER, 'split_v 2870a09082c103050810ffdffffe0204'),
    'e-resize': (at_angle(one_way, 0), CENTER, 'right_side'),
    's-resize': (at_angle(one_way, 90), CENTER, 'bottom_side'),
    'w-resize': (at_angle(one_way, 180), CENTER, 'left_side'),
    'n-resize': (at_angle(one_way, 270), CENTER, 'top_side'),
    'se-resize': (at_angle(one_way, 45, True), CENTER, 'bottom_right_corner lr_angle'),
    'sw-resize': (at_angle(one_way, 135, True), CENTER, 'bottom_left_corner ll_angle'),
    'nw-resize': (at_angle(one_way, 225, True), CENTER, 'top_left_corner ul_angle'),
    'ne-resize': (at_angle(one_way, 315, True), CENTER, 'top_right_corner ur_angle'),
}
ANIMATED = {'wait', 'progress'}


def picture(st, name, size, frame=0):
    art = Art(size >= 48)
    draw = CURSORS[name][0]
    if name in ANIMATED:
        draw(st, art, 360 * frame / FRAMES)
    else:
        draw(st, art)
    return art.svg()


def build(st, out, rsvg, convert, xcursorgen):
    cursors = os.path.join(out, 'cursors')
    work = os.path.join(out, 'work')
    os.makedirs(cursors)
    os.makedirs(work)
    with open(os.path.join(out, 'index.theme'), 'w') as f:
        f.write(f'[Icon Theme]\nName={st.name}\nInherits=Adwaita\n')

    def frames(name):
        return range(FRAMES if name in ANIMATED else 1)

    def render(job):
        name, size, frame = job
        base = os.path.join(work, f'{name}-{size}-{frame}')
        with open(base + '.svg', 'w') as f:
            f.write(picture(st, name, size, frame))
        big = str(size * OVERSAMPLE)
        subprocess.run([rsvg, '-w', big, '-h', big, '-o', base + '-big.png', base + '.svg'], check=True)
        subprocess.run([convert, base + '-big.png', '-filter', 'Lanczos', '-resize', f'{size}x{size}', '-depth', '8',
                        f'PNG32:{base}.png'], check=True)

    jobs = [(name, size, frame) for name in CURSORS for size in SIZES for frame in frames(name)]
    with ThreadPoolExecutor(os.cpu_count() or 1) as pool:
        list(pool.map(render, jobs))
    for name, (_, hot, others) in CURSORS.items():
        config = os.path.join(work, f'{name}.cfg')
        with open(config, 'w') as f:
            for size in SIZES:
                x, y = round(hot.real * size / 64), round(hot.imag * size / 64)
                for frame in frames(name):
                    f.write(f'{size} {x} {y} {work}/{name}-{size}-{frame}.png {FRAME_MS}\n')
        subprocess.run([xcursorgen, config, os.path.join(cursors, name)], check=True)
        for other in others.split():
            os.symlink(name, os.path.join(cursors, other))
    shutil.rmtree(work)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('mode', choices=('day', 'night'))
    parser.add_argument('palette', help='a file of "name #rrggbb" lines')
    parser.add_argument('out')
    parser.add_argument('--svg', action='store_true', help='just write the 68px pictures, to look at')
    parser.add_argument('--frame', type=int, default=9, help='which frame of the animations, with --svg')
    parser.add_argument('--rsvg', default='rsvg-convert')
    parser.add_argument('--convert', default='convert')
    parser.add_argument('--xcursorgen', default='xcursorgen')
    args = parser.parse_args()
    with open(args.palette) as f:
        palette = dict(entry.split() for entry in f.read().strip().splitlines())
    st = (Marseille if args.mode == 'day' else Arcana)(palette)
    if args.svg:
        os.makedirs(args.out, exist_ok=True)
        for name in CURSORS:
            with open(os.path.join(args.out, name + '.svg'), 'w') as f:
                f.write(picture(st, name, 68, args.frame))
    else:
        build(st, args.out, args.rsvg, args.convert, args.xcursorgen)


if __name__ == '__main__':
    main()
