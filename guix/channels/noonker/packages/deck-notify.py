#!/usr/bin/env python3
"""A freedesktop notification daemon that draws notifications as a deck of cards.

The newest notification is the face-up card on top of the deck.  Its rank is
the number of cards in the deck, its suit is the sending application's icon,
and its text is the notification.  Everything underneath is face down.

Mouse: left = run the default action and discard the top card,
       right = discard the top card, middle = discard the whole deck.
"""

import configparser
import math
import os
import random
import re
import signal
import sys

# theme-switch sends SIGUSR1, and at login it runs while this is still starting.
# Until main() installs its handler the default action would kill us, so ignore
# it before the slow imports; main() reads the current theme anyway.
signal.signal(signal.SIGUSR1, signal.SIG_IGN)

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")

import cairo  # noqa: E402
from gi.repository import (  # noqa: E402
    Gdk,
    GdkPixbuf,
    Gio,
    GLib,
    Gtk,
    GtkLayerShell,
    Pango,
    PangoCairo,
)

# Behaviour
DEFAULT_TIMEOUT_MS = 7000  # used when the sender doesn't ask for a timeout
MAX_BACK_CARDS = 5  # face-down cards drawn; the rank still counts them all

# Geometry, in logical pixels.  Cards have poker proportions (5:7).
CARD_W, CARD_H = 165, 231
CARD_RADIUS = 7
RULE_INSET = 3  # from the card edge to the double rule, which is RULE_WIDTH deep
RULE_WIDTH = 7
CORNER_INSET = 13  # corner index distance from the card edge, clear of the rule
SUIT_SIZE = 18
TEXT_INSET_X = 14
TEXT_INSET_Y = 56  # keeps the text clear of both corner indices
DECK_DX, DECK_DY = 3, 3  # how far each lower card sticks out, down and left
MAX_TILT_DEG = 3
PAD = 9  # transparent room for tilted cards to overflow into
ICON_PX = SUIT_SIZE * 2  # rendered at 2x so HiDPI outputs stay crisp

# Theme.  These are the defaults; load_theme() replaces them when the desktop
# theme changes (on startup, and on SIGUSR1).
THEME_FILE = os.path.expanduser("~/.local/state/theme/current/deck-notify.conf")
BACK_PATTERN = "hatch"  # or "stars"
RULE = (0x0c / 255, 0x12 / 255, 0x1a / 255)
RULE_CUT = "rough"  # hand-cut like a woodblock, or "fine"
BACKGROUND = (0x1c / 255, 0x1f / 255, 0x26 / 255)
ACCENT = (0x89 / 255, 0xaa / 255, 0xeb / 255)
CRITICAL = (0xf3 / 255, 0x8b / 255, 0xa8 / 255)
TEXT = (0xe6 / 255, 0xe9 / 255, 0xef / 255)
RANK_FONT = "JetBrains Mono Bold 11"
TEXT_FONT = "JetBrains Mono 8"
FALLBACK_SUIT_FONT = "Sans 14"

WIN_W = CARD_W + MAX_BACK_CARDS * DECK_DX + 2 * PAD
WIN_H = CARD_H + MAX_BACK_CARDS * DECK_DY + 2 * PAD
FRONT_X = WIN_W - PAD - CARD_W
FRONT_Y = PAD

BUS_NAME = "org.freedesktop.Notifications"
OBJECT_PATH = "/org/freedesktop/Notifications"
INTERFACE_XML = f"""
<node>
  <interface name="{BUS_NAME}">
    <method name="GetCapabilities"><arg type="as" direction="out"/></method>
    <method name="Notify">
      <arg type="s" direction="in"/><arg type="u" direction="in"/>
      <arg type="s" direction="in"/><arg type="s" direction="in"/>
      <arg type="s" direction="in"/><arg type="as" direction="in"/>
      <arg type="a{{sv}}" direction="in"/><arg type="i" direction="in"/>
      <arg type="u" direction="out"/>
    </method>
    <method name="CloseNotification"><arg type="u" direction="in"/></method>
    <method name="GetServerInformation">
      <arg type="s" direction="out"/><arg type="s" direction="out"/>
      <arg type="s" direction="out"/><arg type="s" direction="out"/>
    </method>
    <signal name="NotificationClosed"><arg type="u"/><arg type="u"/></signal>
    <signal name="ActionInvoked"><arg type="u"/><arg type="s"/></signal>
  </interface>
</node>
"""

REASON_EXPIRED, REASON_DISMISSED, REASON_CLOSED = 1, 2, 3
URGENCY_CRITICAL = 2


def hex_color(value):
    return tuple(int(value[i:i + 2], 16) / 255 for i in (1, 3, 5))


def load_theme():
    global BACKGROUND, ACCENT, CRITICAL, TEXT, BACK_PATTERN, RULE, RULE_CUT
    parser = configparser.ConfigParser(interpolation=None)
    try:
        parser.read(THEME_FILE)
        card = parser["card"]
        BACKGROUND = hex_color(card["background"])
        ACCENT = hex_color(card["accent"])
        CRITICAL = hex_color(card["critical"])
        TEXT = hex_color(card["text"])
        BACK_PATTERN = card["pattern"]
        RULE = hex_color(card["rule"])
        RULE_CUT = card["rule_cut"]
    except (configparser.Error, KeyError, ValueError) as error:
        print(f"deck-notify: keeping current theme: {error!r}", file=sys.stderr)


# Icons ---------------------------------------------------------------------

def themed_pixbuf(lookup):
    """Load a Gtk.IconInfo, tinting symbolic icons so they show on the dark card."""
    if lookup is None:
        return None
    if lookup.is_symbolic():
        fg = Gdk.RGBA(*TEXT, 1.0)
        return lookup.load_symbolic(fg, None, None, None)[0]
    return lookup.load_icon()


def icon_from_name(name):
    """NAME is what app_icon holds: an icon name, a path, or a file:// URI."""
    if name.startswith("file://"):
        name = GLib.filename_from_uri(name)[0]
    if name.startswith("/"):
        return GdkPixbuf.Pixbuf.new_from_file_at_scale(name, ICON_PX, ICON_PX, True)
    theme = Gtk.IconTheme.get_default()
    return themed_pixbuf(
        theme.lookup_icon(name, ICON_PX, Gtk.IconLookupFlags.FORCE_SIZE)
    )


def icon_from_desktop_entry(entry):
    entry = entry.removesuffix(".desktop")
    info = Gio.DesktopAppInfo.new(entry + ".desktop")
    gicon = info.get_icon() if info else None
    if gicon is None:
        return None
    theme = Gtk.IconTheme.get_default()
    return themed_pixbuf(
        theme.lookup_by_gicon(gicon, ICON_PX, Gtk.IconLookupFlags.FORCE_SIZE)
    )


def icon_from_image_data(data):
    """Decode the (iiibiiay) struct of the image-data hint."""
    width, height, rowstride, has_alpha, bits, _channels, pixels = data
    if bits != 8 or rowstride * height > len(pixels):
        return None
    pixbuf = GdkPixbuf.Pixbuf.new_from_bytes(
        GLib.Bytes.new(bytes(pixels)),
        GdkPixbuf.Colorspace.RGB,
        has_alpha,
        bits,
        width,
        height,
        rowstride,
    )
    scale = ICON_PX / max(width, height)
    return pixbuf.scale_simple(
        max(1, round(width * scale)),
        max(1, round(height * scale)),
        GdkPixbuf.InterpType.BILINEAR,
    )


def resolve_suit(app_name, app_icon, hints):
    """Find the application's icon.

    The spec ranks image hints first, but those are usually content (an avatar,
    album art) and the suit should identify the application, so they come last.
    """
    attempts = []
    if hints.get("desktop-entry"):
        attempts.append((icon_from_desktop_entry, hints["desktop-entry"]))
    if app_icon:
        attempts.append((icon_from_name, app_icon))
    if app_name:
        attempts.append((icon_from_name, app_name.lower().replace(" ", "-")))
    for key in ("image-data", "image_data", "icon_data"):
        if key in hints:
            attempts.append((icon_from_image_data, hints[key]))
    for key in ("image-path", "image_path"):
        if hints.get(key):
            attempts.append((icon_from_name, hints[key]))

    for load, arg in attempts:
        try:
            pixbuf = load(arg)
        except (GLib.Error, TypeError, ValueError):
            continue
        if pixbuf is not None:
            return pixbuf
    return None  # drawn as a plain spade


# Text ----------------------------------------------------------------------

def body_to_markup(body):
    """Reduce a notification body to Pango markup we know will parse.

    The spec only allows b/i/u/a/img; <a> and <img> aren't Pango tags, and many
    senders put unescaped text here, so anything unparseable is shown literally.
    """
    markup = re.sub(r"</?(?![biu]>)[a-zA-Z][^>]*>", "", body)
    markup = re.sub(r"&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)", "&amp;", markup)
    try:
        Pango.parse_markup(markup, -1, "\0")
    except GLib.Error:
        return GLib.markup_escape_text(body, -1)
    return markup


def card_markup(summary, body):
    parts = []
    if summary:
        parts.append(f"<b>{GLib.markup_escape_text(summary, -1)}</b>")
    if body:
        parts.append(body_to_markup(body))
    return "\n\n".join(parts)


# Drawing -------------------------------------------------------------------

def card_path(cr):
    r, w, h = CARD_RADIUS, CARD_W, CARD_H
    cr.new_sub_path()
    cr.arc(w - r, r, r, -math.pi / 2, 0)
    cr.arc(w - r, h - r, r, 0, math.pi / 2)
    cr.arc(r, h - r, r, math.pi / 2, math.pi)
    cr.arc(r, r, r, math.pi, 3 * math.pi / 2)
    cr.close_path()


def wobble(rng, length, amplitude):
    """A smooth, random offset along an edge, as a function of the distance along it."""
    terms = [
        (k, rng.uniform(0.4, 1) * amplitude / k ** 0.5, rng.uniform(0, 2 * math.pi))
        for k in (1, 2, 3, 5, 8, 13)
    ]
    return lambda t: sum(a * math.sin(2 * math.pi * k * t / length + p) for k, a, p in terms)


def rule_edge(cr, rng, inset, amplitude):
    """Trace a closed rectangle INSET from the card's edge, its sides a little unsteady."""
    x0, y0, x1, y1 = inset, inset, CARD_W - inset, CARD_H - inset
    sides = (
        ((x0, y0), (x1, y0), (0, 1)),
        ((x1, y0), (x1, y1), (-1, 0)),
        ((x1, y1), (x0, y1), (0, -1)),
        ((x0, y1), (x0, y0), (1, 0)),
    )
    for (ax, ay), (bx, by), (nx, ny) in sides:
        length = math.hypot(bx - ax, by - ay)
        offset = wobble(rng, length, amplitude)
        steps = max(2, int(length / 4))
        for i in range(steps + 1):
            t = length * i / steps
            d = offset(t)
            cr.line_to(ax + (bx - ax) * i / steps + nx * d, ay + (by - ay) * i / steps + ny * d)
    cr.close_path()


def draw_rule(cr, seed, color):
    """The double rule from the waybar frame: a heavy line outside a thin one.

    It's filled between two separately wobbling edges, so its weight varies as a
    cut line's does.  The seed keeps a card's rule the same between redraws.
    """
    rough = RULE_CUT == "rough"
    amplitude = 0.35 if rough else 0
    heavy, gap = (3.2, 1.6) if rough else (1, 2.2)
    thin = RULE_WIDTH - heavy - gap if rough else 0.6
    rng = random.Random(seed)
    edges = (
        RULE_INSET,
        RULE_INSET + heavy,
        RULE_INSET + heavy + gap,
        RULE_INSET + heavy + gap + thin,
    )
    cr.save()
    cr.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    cr.new_path()
    for inset in edges:
        cr.new_sub_path()
        rule_edge(cr, rng, inset, amplitude)
    cr.set_source_rgb(*color)
    cr.fill()
    cr.restore()


def draw_card_base(cr, seed, color):
    card_path(cr)
    cr.set_source_rgb(*BACKGROUND)
    cr.fill_preserve()
    cr.set_source_rgba(*color, 0.5)
    cr.set_line_width(1)
    cr.stroke()
    draw_rule(cr, seed, color)


def draw_stars(cr, seed, count, alpha):
    """Scatter stars over the card; the same seed always gives the same sky."""
    rng = random.Random(seed)
    cr.set_source_rgba(*TEXT, alpha)
    for _ in range(count):
        x, y = rng.uniform(0, CARD_W), rng.uniform(0, CARD_H)
        size = rng.choice((0.6, 0.6, 0.9, 1.2))
        cr.arc(x, y, size, 0, 2 * math.pi)
        cr.fill()
        if rng.random() < 0.12:  # the odd four-pointed sparkle
            arm = rng.uniform(3, 5)
            cr.set_line_width(0.6)
            cr.move_to(x - arm, y)
            cr.line_to(x + arm, y)
            cr.move_to(x, y - arm)
            cr.line_to(x, y + arm)
            cr.stroke()


def draw_hatch(cr):
    """Cross-hatch, like the back of a traditional deck."""
    cr.set_source_rgba(*ACCENT, 0.3)
    cr.set_line_width(1)
    span = CARD_W + CARD_H
    for offset in range(-CARD_H, CARD_W, 9):
        cr.move_to(offset, 0)
        cr.line_to(offset + span, span)
        cr.move_to(offset + CARD_H, 0)
        cr.line_to(offset + CARD_H - span, span)
    cr.stroke()


def draw_card_back(cr, note):
    cr.save()
    cr.translate(CARD_W / 2, CARD_H / 2)
    cr.rotate(note.tilt)
    cr.translate(-CARD_W / 2, -CARD_H / 2)
    draw_card_base(cr, note.id, RULE)

    cr.save()
    inner = RULE_INSET + RULE_WIDTH
    cr.rectangle(inner, inner, CARD_W - 2 * inner, CARD_H - 2 * inner)
    cr.clip()
    if BACK_PATTERN == "stars":
        draw_stars(cr, note.id, 124, 0.8)
    else:
        draw_hatch(cr)
    cr.restore()
    cr.restore()


def draw_suit(cr, pixbuf, x, y):
    if pixbuf is None:
        layout = PangoCairo.create_layout(cr)
        layout.set_font_description(Pango.FontDescription.from_string(FALLBACK_SUIT_FONT))
        layout.set_text("♠", -1)
        width, height = layout.get_pixel_size()
        cr.set_source_rgb(*TEXT)
        cr.move_to(x + (SUIT_SIZE - width) / 2, y + (SUIT_SIZE - height) / 2)
        PangoCairo.show_layout(cr, layout)
        return
    cr.save()
    scale = SUIT_SIZE / max(pixbuf.get_width(), pixbuf.get_height())
    cr.translate(
        x + (SUIT_SIZE - pixbuf.get_width() * scale) / 2,
        y + (SUIT_SIZE - pixbuf.get_height() * scale) / 2,
    )
    cr.scale(scale, scale)
    Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0)
    cr.get_source().set_filter(cairo.FILTER_BEST)
    cr.paint()
    cr.restore()


def draw_corner(cr, rank, suit, color):
    """Draw the top-left index: rank over suit, centred on the same axis."""
    layout = PangoCairo.create_layout(cr)
    layout.set_font_description(Pango.FontDescription.from_string(RANK_FONT))
    layout.set_text(rank, -1)
    width, height = layout.get_pixel_size()
    cr.set_source_rgb(*color)
    cr.move_to(CORNER_INSET + (SUIT_SIZE - width) / 2, CORNER_INSET)
    PangoCairo.show_layout(cr, layout)
    draw_suit(cr, suit, CORNER_INSET, CORNER_INSET + height + 2)


def draw_card_front(cr, note, rank):
    color = CRITICAL if note.urgency == URGENCY_CRITICAL else ACCENT
    draw_card_base(cr, note.id, CRITICAL if note.urgency == URGENCY_CRITICAL else RULE)
    if BACK_PATTERN == "stars":  # a faint sky behind the night cards' text
        cr.save()
        inner = RULE_INSET + RULE_WIDTH
        cr.rectangle(inner, inner, CARD_W - 2 * inner, CARD_H - 2 * inner)
        cr.clip()
        draw_stars(cr, note.id, 22, 0.25)
        cr.restore()

    draw_corner(cr, rank, note.suit, color)
    cr.save()  # the opposite corner is the same index, upside down
    cr.translate(CARD_W, CARD_H)
    cr.rotate(math.pi)
    draw_corner(cr, rank, note.suit, color)
    cr.restore()

    text_w = CARD_W - 2 * TEXT_INSET_X
    text_h = CARD_H - 2 * TEXT_INSET_Y
    layout = PangoCairo.create_layout(cr)
    layout.set_font_description(Pango.FontDescription.from_string(TEXT_FONT))
    layout.set_width(text_w * Pango.SCALE)
    layout.set_height(text_h * Pango.SCALE)
    layout.set_wrap(Pango.WrapMode.WORD_CHAR)
    layout.set_ellipsize(Pango.EllipsizeMode.END)
    layout.set_alignment(Pango.Alignment.CENTER)
    layout.set_markup(note.markup, -1)
    _, height = layout.get_pixel_size()
    cr.set_source_rgb(*TEXT)
    cr.move_to(TEXT_INSET_X, TEXT_INSET_Y + max(0, (text_h - height) / 2))
    PangoCairo.show_layout(cr, layout)


# Daemon --------------------------------------------------------------------

class Note:
    def __init__(self, note_id):
        self.id = note_id
        self.tilt = math.radians(random.uniform(-MAX_TILT_DEG, MAX_TILT_DEG))
        self.timer = None
        self.markup = ""
        self.suit = None
        self.actions = []
        self.urgency = 1


class Deck:
    def __init__(self):
        self.notes = []  # oldest first; the last one is the top of the deck
        self.next_id = 1
        self.connection = None

        self.window = Gtk.Window()
        self.window.set_app_paintable(True)
        visual = self.window.get_screen().get_rgba_visual()
        if visual:
            self.window.set_visual(visual)
        GtkLayerShell.init_for_window(self.window)
        GtkLayerShell.set_namespace(self.window, "deck-notify")
        GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_keyboard_mode(self.window, GtkLayerShell.KeyboardMode.NONE)

        self.area = Gtk.DrawingArea()
        self.area.set_size_request(WIN_W, WIN_H)
        self.area.connect("draw", self.on_draw)
        self.window.add(self.area)
        self.window.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        self.window.connect("button-press-event", self.on_button)
        self.area.show()

    # Rendering

    def on_draw(self, _area, cr):
        cr.set_operator(cairo.OPERATOR_CLEAR)
        cr.paint()
        cr.set_operator(cairo.OPERATOR_OVER)
        if not self.notes:
            return False

        backs = self.notes[:-1][-MAX_BACK_CARDS:]
        for index, note in enumerate(backs):
            depth = len(backs) - index
            cr.save()
            cr.translate(FRONT_X - depth * DECK_DX, FRONT_Y + depth * DECK_DY)
            draw_card_back(cr, note)
            cr.restore()

        cr.save()
        cr.translate(FRONT_X, FRONT_Y)
        draw_card_front(cr, self.notes[-1], str(len(self.notes)))
        cr.restore()
        return False

    def on_theme_changed(self):
        load_theme()
        self.area.queue_draw()
        return GLib.SOURCE_CONTINUE

    def refresh(self):
        if self.notes:
            self.window.show()
            self.area.queue_draw()
        else:
            self.window.hide()

    # Mouse

    def on_button(self, _window, event):
        if not self.notes:
            return True
        top = self.notes[-1]
        if event.button == Gdk.BUTTON_PRIMARY:
            if "default" in top.actions[::2]:
                self.emit("ActionInvoked", GLib.Variant("(us)", (top.id, "default")))
            self.close(top.id, REASON_DISMISSED)
        elif event.button == Gdk.BUTTON_SECONDARY:
            self.close(top.id, REASON_DISMISSED)
        elif event.button == Gdk.BUTTON_MIDDLE:
            for note in list(self.notes):
                self.close(note.id, REASON_DISMISSED)
        return True

    # Deck operations

    def find(self, note_id):
        return next((n for n in self.notes if n.id == note_id), None)

    def allocate_id(self):
        while self.find(self.next_id) or self.next_id == 0:
            self.next_id = (self.next_id + 1) & 0xFFFFFFFF
        note_id = self.next_id
        self.next_id = (self.next_id + 1) & 0xFFFFFFFF
        return note_id

    def notify(self, app_name, replaces_id, app_icon, summary, body, actions, hints, timeout):
        note = self.find(replaces_id) if replaces_id else None
        if note is None:
            note = Note(replaces_id or self.allocate_id())
            self.notes.append(note)
        self.cancel_timer(note)

        note.markup = card_markup(summary, body)
        note.suit = resolve_suit(app_name, app_icon, hints)
        note.actions = actions
        note.urgency = hints.get("urgency", 1)

        if timeout < 0:  # sender left it to us; critical cards stay until dismissed
            timeout = 0 if note.urgency == URGENCY_CRITICAL else DEFAULT_TIMEOUT_MS
        if timeout > 0:
            note.timer = GLib.timeout_add(timeout, self.on_expired, note.id)

        self.refresh()
        return note.id

    def on_expired(self, note_id):
        note = self.find(note_id)
        if note:
            note.timer = None  # returning False already removes the source
            self.close(note_id, REASON_EXPIRED)
        return False

    def cancel_timer(self, note):
        if note.timer is not None:
            GLib.source_remove(note.timer)
            note.timer = None

    def close(self, note_id, reason):
        note = self.find(note_id)
        if note is None:
            return
        self.cancel_timer(note)
        self.notes.remove(note)
        self.emit("NotificationClosed", GLib.Variant("(uu)", (note_id, reason)))
        self.refresh()

    # D-Bus

    def emit(self, signal, params):
        if self.connection:
            self.connection.emit_signal(None, OBJECT_PATH, BUS_NAME, signal, params)

    def on_method_call(self, _conn, _sender, _path, _iface, method, params, invocation):
        if method == "GetCapabilities":
            caps = ["actions", "body", "body-markup", "icon-static"]
            invocation.return_value(GLib.Variant("(as)", (caps,)))
        elif method == "GetServerInformation":
            info = ("deck-notify", "noonker", "0.1.0", "1.2")
            invocation.return_value(GLib.Variant("(ssss)", info))
        elif method == "CloseNotification":
            self.close(params.unpack()[0], REASON_CLOSED)
            invocation.return_value(None)
        elif method == "Notify":
            note_id = self.notify(*params.unpack())
            invocation.return_value(GLib.Variant("(u)", (note_id,)))

    def on_bus_acquired(self, connection, _name):
        self.connection = connection
        interface = Gio.DBusNodeInfo.new_for_xml(INTERFACE_XML).interfaces[0]
        connection.register_object_with_closures2(
            OBJECT_PATH, interface, self.on_method_call, None, None
        )


def on_name_lost(_connection, name):
    print(f"deck-notify: could not own {name}; is another daemon running?", file=sys.stderr)
    sys.exit(1)


def main():
    load_theme()
    deck = Deck()
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, deck.on_theme_changed)
    Gio.bus_own_name(
        Gio.BusType.SESSION,
        BUS_NAME,
        Gio.BusNameOwnerFlags.NONE,
        deck.on_bus_acquired,
        None,
        on_name_lost,
    )
    Gtk.main()


if __name__ == "__main__":
    main()
