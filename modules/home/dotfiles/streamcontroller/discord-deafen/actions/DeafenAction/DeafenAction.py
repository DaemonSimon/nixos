import os
import json
import time
import stat
import socket
import struct
import uuid

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

from src.backend.PluginManager.ActionBase import ActionBase

HANDSHAKE = 0
FRAME = 1
CLOSE = 2
CLIENT_ID = "streamcontroller_deafen_plugin"


class DeafenAction(ActionBase):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def on_ready(self):
        icon_path = os.path.join(self.plugin_base.PATH, "assets", "info.png")
        self.set_media(media_path=icon_path, size=0.75)

    def on_key_down(self):
        try:
            self.toggle_deafen()
        except Exception as error:
            print(f"[DeafenAction] Failed to toggle deafen: {error}")

    def on_key_up(self):
        pass

    def find_ipc_socket(self):
        runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
        base_dirs = [
            os.path.join(runtime_dir, "app", "dev.vencord.Vesktop"),
            os.path.join(runtime_dir, "app", "com.discordapp.Discord"),
            runtime_dir,
            "/tmp",
        ]

        tried = set()
        for base_dir in base_dirs:
            for index in range(10):
                path = os.path.join(base_dir, f"discord-ipc-{index}")
                if path in tried:
                    continue
                tried.add(path)

                try:
                    if not stat.S_ISSOCK(os.stat(path).st_mode):
                        continue
                except OSError:
                    continue

                sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                sock.settimeout(3.0)
                try:
                    sock.connect(path)
                    return sock, path
                except OSError as error:
                    sock.close()
                    print(f"[DeafenAction] Could not connect to {path}: {error}")

        return None, None

    @staticmethod
    def send_frame(sock, opcode, payload):
        body = json.dumps(payload).encode("utf-8")
        header = struct.pack("<II", opcode, len(body))
        sock.sendall(header + body)

    @staticmethod
    def recv_exact(sock, size):
        buffer = b""
        while len(buffer) < size:
            chunk = sock.recv(size - len(buffer))
            if not chunk:
                return None
            buffer += chunk
        return buffer

    def recv_frame(self, sock):
        header = self.recv_exact(sock, 8)
        if header is None:
            return None
        opcode, length = struct.unpack("<II", header)
        payload = self.recv_exact(sock, length)
        return opcode, payload

    def recv_response(self, sock, command, nonce):
        deadline = time.time() + 3.0
        while time.time() < deadline:
            frame = self.recv_frame(sock)
            if frame is None:
                break
            opcode, payload = frame
            if payload is None:
                continue
            try:
                data = json.loads(payload.decode("utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                continue
            if data.get("nonce") == nonce or data.get("cmd") == command:
                return data
        raise RuntimeError(f"No reply received for {command}")

    @staticmethod
    def check_for_error(response):
        if response.get("evt") == "ERROR" or "code" in response:
            raise RuntimeError(f"Discord IPC error: {response}")

    def toggle_deafen(self):
        sock, path = self.find_ipc_socket()
        if sock is None:
            print("[DeafenAction] No Vesktop/Discord IPC socket found")
            return None

        try:
            self.send_frame(sock, HANDSHAKE, {"v": 1, "client_id": CLIENT_ID})
            opcode, payload = self.recv_frame(sock)
            if payload is None:
                raise RuntimeError("IPC handshake failed")
            handshake = json.loads(payload.decode("utf-8"))
            self.check_for_error(handshake)
            print(f"[DeafenAction] Connected to {path}")

            nonce = str(uuid.uuid4())
            self.send_frame(sock, FRAME, {
                "cmd": "GET_VOICE_SETTINGS",
                "nonce": nonce,
            })
            response = self.recv_response(sock, "GET_VOICE_SETTINGS", nonce)
            self.check_for_error(response)
            new_deaf = not bool(response["data"]["deaf"])

            nonce = str(uuid.uuid4())
            self.send_frame(sock, FRAME, {
                "cmd": "SET_VOICE_SETTINGS",
                "args": {"deaf": new_deaf},
                "nonce": nonce,
            })
            response = self.recv_response(sock, "SET_VOICE_SETTINGS", nonce)
            self.check_for_error(response)

            print(f"[DeafenAction] Deafen {'enabled' if new_deaf else 'disabled'}")
            return new_deaf
        finally:
            try:
                self.send_frame(sock, CLOSE, {})
            except OSError:
                pass
            sock.close()
