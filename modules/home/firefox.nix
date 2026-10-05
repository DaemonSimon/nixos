{ ... }:

{
  programs.firefox = {
    enable = true;
    profiles.default = {
      path = "3p3pbhcm.default";
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.inTitlebar" = false;
        "browser.tabs.drawInTitlebar" = false;
      };
      userChrome = ./dotfiles/firefox/userChrome.css;
      userContent = ./dotfiles/firefox/userContent.css;
    };
  };
}
