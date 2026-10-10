# StreamController plugin - control Discord (Vesktop) mute/deafen from the deck.
from loguru import logger

from src.backend.PluginManager.PluginBase import PluginBase
from src.backend.PluginManager.ActionHolder import ActionHolder

from .vesktop_bridge import VesktopBridge
from .actions.DeafenAction.DeafenAction import DeafenAction
from .actions.MuteAction.MuteAction import MuteAction

PLUGIN_ID = "com_simon_DiscordDeafen"
GITHUB_REPO = "https://github.com/StreamController/PluginTemplate"


class DiscordDeafen(PluginBase):
    """Exposes mute/deafen actions that talk to a local Vesktop bridge.

    The bridge is a tiny HTTP server that runs inside Vesktop's main process;
    it clicks Discord's own mute/deafen buttons, so the state is sent to
    Discord and visible to everyone in the call.
    """

    def __init__(self):
        super().__init__()

        # Shared bridge client. Actions reach it via `self.plugin_base.bridge`.
        self.bridge = VesktopBridge()

        self.add_action_holder(
            ActionHolder(
                plugin_base=self,
                action_base=DeafenAction,
                action_id=f"{PLUGIN_ID}::DeafenAction",
                action_name="Discord Deafen",
            )
        )
        self.add_action_holder(
            ActionHolder(
                plugin_base=self,
                action_base=MuteAction,
                action_id=f"{PLUGIN_ID}::MuteAction",
                action_name="Discord Mute",
            )
        )

        self.register(
            plugin_name="Discord Deafen",
            github_repo=GITHUB_REPO,
            plugin_version="1.0.0",
            app_version="1.0.0",
        )

    def prepare_action_defaults(self, action) -> None:
        """Let a freshly placed action own its icon and label slots.

        Without this an action dropped onto a key may not control the image or
        label, so its icon/label would not show by default.
        """
        try:
            state = action.get_state()
            if state is None:
                return

            permissions = state.action_permission_manager
            own_index = action.get_own_action_index()
            if own_index in (None, -1):
                return

            if permissions.get_image_control_index() is None or not action.get_is_multi_action():
                if permissions.get_image_control_index() != own_index:
                    permissions.set_image_control_index(own_index, reload_pages=False, reload_self=False)

            if permissions.get_label_control_index(2) is None or not action.get_is_multi_action():
                if permissions.get_label_control_index(2) != own_index:
                    permissions.set_label_control_index(2, own_index, reload_pages=False, reload_self=False)
        except Exception as error:
            logger.error(f"Discord Deafen: could not claim default image/label control: {error}")
