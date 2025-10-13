# 52.01 Distrobox Container Configuration
# Container definitions for different development environments
{ inputs, ... }:

{
  home-manager.users.lessuseless = { pkgs, ... }: {
    # Session variables for container integration
    home.sessionVariables = {
      SUMMON_PROVIDER_PATH = "${pkgs.gopass-summon-provider}/bin";
    };

    # Distrobox configuration
    programs.distrobox = {
      enable = true;
      containers = {
        # Python development container
        "python-project" = {
          image = "fedora:40";
          additional_packages = "python3 git";
          init_hooks = "pip3 install numpy pandas torch torchvision";
        };

        # Common Debian base container
        "common-debian" = {
          image = "debian:13";
          entry = true;
          additional_packages = "git";
          init_hooks = [
            # Docker host integration
            "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker"
            "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker-compose"
          ];
        };

        # Office productivity container
        "office" = {
          clone = "common-debian";
          additional_packages = "libreoffice onlyoffice";
          entry = true;
        };
      };
    };
  };
}