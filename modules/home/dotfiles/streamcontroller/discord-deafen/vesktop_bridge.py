"""Client for the local Vesktop control bridge.

The bridge is a small HTTP server that runs inside Vesktop's main process
(installed via `vesktop/install-bridge.sh`). It clicks Discord's own
mute/deafen buttons, so the state change is sent to Discord - not just
muted locally - and every participant can see it.

Endpoints:
    GET /ping    -> "pong" when the bridge is alive
    GET /mute    -> toggles mute,   returns the button label that was clicked
    GET /deafen  -> toggles deafen, returns the button label that was clicked
"""

import urllib.error
import urllib.request

DEFAULT_URL = "http://127.0.0.1:6459"


class BridgeError(RuntimeError):
    """Raised when the Vesktop bridge cannot be reached."""


class VesktopBridge:
    def __init__(self, base_url: str = DEFAULT_URL, timeout: float = 2.0):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    def _get(self, path: str) -> str:
        url = f"{self.base_url}/{path.lstrip('/')}"
        try:
            with urllib.request.urlopen(url, timeout=self.timeout) as response:
                return response.read().decode("utf-8").strip()
        except (urllib.error.URLError, OSError) as error:
            raise BridgeError(
                f"Vesktop bridge is not reachable at {self.base_url} "
                f"(is Vesktop running with the bridge installed?): {error}"
            ) from error

    def ping(self) -> bool:
        try:
            return self._get("ping") == "pong"
        except BridgeError:
            return False

    def toggle_mute(self) -> str:
        return self._get("mute")

    def toggle_deafen(self) -> str:
        return self._get("deafen")
