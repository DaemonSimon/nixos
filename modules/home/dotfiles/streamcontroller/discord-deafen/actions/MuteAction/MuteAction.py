import os

from loguru import logger

from src.backend.PluginManager.ActionBase import ActionBase


class MuteAction(ActionBase):
    """Toggles Discord mute through the Vesktop bridge."""

    def on_ready(self) -> None:
        self.plugin_base.prepare_action_defaults(self)
        self.set_media(
            media_path=os.path.join(self.plugin_base.PATH, "assets", "info.png"),
            size=0.75,
        )
        self.set_bottom_label(
            "Mute" if self.plugin_base.bridge.ping() else "No bridge",
            font_size=12,
        )

    def on_key_down(self) -> None:
        try:
            result = self.plugin_base.bridge.toggle_mute()
            logger.info(f"Discord Mute: bridge replied '{result}'")
        except Exception as error:
            logger.error(f"Discord Mute: {error}")

    def on_key_up(self) -> None:
        pass
