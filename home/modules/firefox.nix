{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        gaoptout
      ];
      settings = {
        "browser.translations.neverTranslateLanguages" = "ja,en";
        "services.sync.client.name" = "mbp-2024";
      };
      search = {
        force = true;
        default = "Kagi";
        privateDefault = "ddg";
        engines = {
          "Scrapbox kanna" = {
            urls = [{template = "https://scrapbox.io/kanna/search/page?q={searchTerms}";}];
            icon = "https://scrapbox.io/favicon.ico";
            definedAliases = ["s"];
          };
          "Scrapbox Private" = {
            urls = [{template = "https://scrapbox.io/twilight-snow-1630/search/page?q={searchTerms}";}];
            icon = "https://scrapbox.io/favicon.ico";
            definedAliases = ["kan"];
          };
          "Kagi" = {
            urls = [{template = "https://kagi.com/search?q={searchTerms}";}];
            icon = "https://kagi.com/favicon.ico";
            definedAliases = ["k"];
          };
          "NixOS Packages" = {
            urls = [{template = "https://search.nixos.org/packages?query={searchTerms}";}];
            icon = "https://nixos.org/favicon.ico";
            definedAliases = ["nixpkgs"];
          };
          "NixOS Options" = {
            urls = [{template = "https://search.nixos.org/options?query={searchTerms}";}];
            icon = "https://nixos.org/favicon.ico";
            definedAliases = ["nixopts"];
          };
          "Noogle" = {
            urls = [{template = "https://noogle.dev/q?term={searchTerms}";}];
            icon = "https://noogle.dev/favicon.ico";
            definedAliases = ["nixlibs"];
          };
          ddg.metaData.alias = "d";
          bing.metaData.hidden = true;
        };
      };
    };
  };
}
