{ config, ... }:
{
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${config.home.profileDirectory}/bin/awww-daemon";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
