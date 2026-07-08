#!/usr/bin/env python3
"""UDP <-> stdio proxy for the SuperCollider LanguageServer.quark.

The vscode-supercollider extension launches sclang with three env vars
(SCLANG_LSP_ENABLE, SCLANG_LSP_SERVERPORT, SCLANG_LSP_CLIENTPORT) and
speaks LSP JSON-RPC over UDP datagrams on the loopback interface.

Neither eglot nor lsp-mode support UDP transport, so this script bridges:
    stdin  ->  UDP datagrams  ->  sclang
    stdout <-  UDP datagrams  <-  sclang

Prereqs on the sclang side:
    Quarks.install("https://github.com/scztt/LanguageServer.quark");
"""

import argparse
import os
import re
import socket
import subprocess
import sys
import threading


HEADER_RE = re.compile(rb"Content-Length: (\d+)\r\n\r\n")
LSP_READY = b"***LSP READY***"
LSP_ADDRESS = "127.0.0.1"
DATAGRAM_MAX = 65000


def reserve_udp_port() -> int:
    """Bind a UDP port then release it so sclang can grab it."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.bind((LSP_ADDRESS, 0))
        return s.getsockname()[1]


def stdin_to_udp(sock: socket.socket, write_port: int) -> None:
    stdin = sys.stdin.buffer
    buf = b""
    while True:
        chunk = stdin.read1(65536)
        if not chunk:
            return
        buf += chunk
        while True:
            m = HEADER_RE.search(buf)
            if not m:
                break
            length = int(m.group(1))
            body_start = m.end()
            if len(buf) < body_start + length:
                break
            body = buf[body_start:body_start + length]
            buf = buf[body_start + length:]
            framed = m.group(0) + body + b"\n"
            for off in range(0, len(framed), DATAGRAM_MAX):
                sock.sendto(framed[off:off + DATAGRAM_MAX],
                            (LSP_ADDRESS, write_port))


def udp_to_stdout(sock: socket.socket) -> None:
    stdout = sys.stdout.buffer
    buf = b""
    content_length = None
    while True:
        data, _ = sock.recvfrom(65536)
        buf += data
        while True:
            if content_length is None:
                m = HEADER_RE.search(buf)
                if not m:
                    break
                content_length = int(m.group(1))
                buf = buf[m.end():]
            if len(buf) < content_length:
                break
            body = buf[:content_length]
            buf = buf[content_length:]
            framed = f"Content-Length: {len(body)}\r\n\r\n".encode() + body
            stdout.write(framed)
            stdout.flush()
            content_length = None


def pump_sclang_output(proc: subprocess.Popen, ready: threading.Event) -> None:
    for line in iter(proc.stdout.readline, b""):
        sys.stderr.buffer.write(line)
        sys.stderr.buffer.flush()
        if LSP_READY in line:
            ready.set()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sclang", default="sclang")
    ap.add_argument("--conf-yaml", default=None,
                    help="sclang_conf.yaml path (default: sclang's own default)")
    # NB: must be "vscode" for LanguageServer.quark to compile its
    # `scide_vscode/` folder (contains LSPDocument). SC's class-library
    # compiler skips `scide_*` folders that don't match Platform.ideName.
    ap.add_argument("--interpreter-id", default="vscode")
    ap.add_argument("--log-level", default="error",
                    choices=("error", "warning", "info", "debug"))
    ap.add_argument("--ready-timeout", type=float, default=120.0)
    ap.add_argument("sclang_arg", nargs="*",
                    help="additional args passed to sclang")
    args = ap.parse_args()

    read_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    read_sock.bind((LSP_ADDRESS, 0))
    read_port = read_sock.getsockname()[1]
    write_port = reserve_udp_port()

    env = dict(os.environ)
    env["SCLANG_LSP_ENABLE"] = "1"
    env["SCLANG_LSP_SERVERPORT"] = str(read_port)
    env["SCLANG_LSP_CLIENTPORT"] = str(write_port)
    env["SCLANG_LSP_LOGLEVEL"] = args.log_level

    cmd = [args.sclang, "-i", args.interpreter_id]
    if args.conf_yaml:
        cmd += ["-l", args.conf_yaml]
    cmd += args.sclang_arg

    # sclang treats stdin EOF as "quit the REPL", so we hand it an open
    # pipe that we never write to (matches vscode-supercollider's spawn).
    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=env,
    )

    ready = threading.Event()
    threading.Thread(target=pump_sclang_output,
                     args=(proc, ready), daemon=True).start()

    if not ready.wait(timeout=args.ready_timeout):
        sys.stderr.write(
            "sclang-lsp-proxy: timed out waiting for '***LSP READY***'. "
            "Is LanguageServer.quark installed?\n")
        proc.terminate()
        return 1

    threading.Thread(target=stdin_to_udp,
                     args=(read_sock, write_port), daemon=True).start()
    threading.Thread(target=udp_to_stdout,
                     args=(read_sock,), daemon=True).start()

    rc = proc.wait()
    return rc if rc is not None else 0


if __name__ == "__main__":
    sys.exit(main())
