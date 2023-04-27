{ userName ? null
, lib
, ...
}:
let
  allowUnfree = builtins.pathExists (/cyvizen/nixos/nix/allowUnfree);
  config = { config = { allowUnfree = allowUnfree; }; };

  #  Aliases
  callPackage = nixpkgs.callPackage;
  nodejs = nixpkgs.nodejs-slim-18_x;
  nixpkgs = (import sources.cyvizen.nixpkgs config);
  nixpkgsLast = (import sources.cyvizen."nixpkgs-last" config);

  bundled = {
    pkgs = (builtins.mapAttrs (name: value: (import sources.cyvizen."${value}" config)."${name}")) (lib.attrsets.filterAttrs (n: v: !lib.strings.hasInfix "." n) pkgToSource);
    pkgSets = with lib; builtins.mapAttrs (n: v: nixpkgs."${n}" // v) (attrsets.genAttrs pkgSetsUnique (set: (attrsets.filterAttrs (n: v: strings.hasPrefix "${set}." n) pkgSetsFiltered)));
  }
  // (if userName == null
  then
    { }
  else
    { user = import (./. + "/../cyvizens/${userName}/nix/default.nix"); });

  sources = {
    cyvizen = import ./sources.nix;
    user = import (./. + "/../cyvizens/${userName}/nix/sources.nix");
  };
  pkgToSource = with builtins; fromJSON (readFile ../pkgs/pkg-to-source.json);

  # NOTE Recursive set merge & import causes mapping/resolution failures, manual necessary at this time
  # gnomeExtensions = nixpkgs.gnomeExtensions // {argoz = (import sources.cyvizen.nixpkgs {}).gnomeExtensions.argos;};
  pkgSetsFiltered = with lib; builtins.mapAttrs (name: value: (import sources.cyvizen."${value}" config)."${name}") (attrsets.filterAttrs (n: v: strings.hasInfix "." n) pkgToSource);
  pkgSetsUnique = with lib; lists.unique (lists.forEach (builtins.attrNames pkgSetsFiltered) (set: lists.elemAt (strings.splitString "." set) 0));

in
import sources.cyvizen.nixpkgs {
  overlays = [
    (
      final: prev: {
        nix-search-cli = (import sources.cyvizen.nix-search-cli).default;
        niv = (import sources.cyvizen.niv { }).niv;
        nodejs = nodejs;
      }
      // bundled.pkgs
      // bundled.pkgSets
      // (if userName == null
      then { }
      else bundled.user
      )
    )
  ];
  config = {
    allowUnfree = allowUnfree;
    packageOverrides = pkgs: {
      nur = import sources.NUR { inherit pkgs; };
    };
    permittedInsecurePackages = [
      "qtwebkit-5.212.0-alpha4"
    ];
  };
}
