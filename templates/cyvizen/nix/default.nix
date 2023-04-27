let
  allowUnfree = builtins.pathExists (./allowUnfree);
  config = { config = { allowUnfree = allowUnfree; }; };
  sources = import ./sources.nix;
in
# This set will be merged into the Cyvizen overlay with priority, overriding other pkg sources
{
  hello = (import sources.nixpkgs config).hello;
}
