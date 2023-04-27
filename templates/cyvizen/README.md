mount overtop of this directory - its persisted in configuration

user customizable directory use mkDefault upstream for any settings so user can override without issues
should be skeleton directory:
- default.nix
- nixos.nix - for all its settings
- impermenance.nix - for persistence via home-manager
- home-manger.nix - for all its settings
- wireless.nix
- sops.json

user can save and make any changes to this or store in git etc WITHOUT affecting required settings for cyvizen configurations
