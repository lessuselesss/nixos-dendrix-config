# 12.01 Networking Configuration (Flake-Parts Module)
# Network interfaces and connectivity
{ inputs, ... }:

{
  # Contribute networking configuration as a nixosModule
  flake.nixosModules."12.01-networking-config" = { config, lib, pkgs, ... }: {
    networking.hostName = "nixos";
    networking.networkmanager.enable = true;

    # WiFi configuration using sops-encrypted credentials
    # The connection will be created at activation time using the decrypted secrets
    systemd.services.setup-wifi-connection = {
      description = "Setup WiFi connection with encrypted credentials";
      wantedBy = [ "multi-user.target" ];
      after = [ "NetworkManager.service" ];
      wants = [ "NetworkManager.service" ];
      path = with pkgs; [ networkmanager coreutils ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Wait for NetworkManager to be ready
        while ! nmcli general status &>/dev/null; do
          sleep 1
        done

        # Read WiFi credentials from sops-decrypted files
        if [ -f ${config.sops.secrets.wifi-ssid.path} ] && [ -f ${config.sops.secrets.wifi-password.path} ]; then
          WIFI_SSID=$(cat ${config.sops.secrets.wifi-ssid.path})
          WIFI_PASSWORD=$(cat ${config.sops.secrets.wifi-password.path})

          # Check if connection already exists
          if ! nmcli connection show "$WIFI_SSID" &>/dev/null; then
            echo "Creating WiFi connection for $WIFI_SSID..."
            nmcli connection add \
              type wifi \
              con-name "$WIFI_SSID" \
              ssid "$WIFI_SSID" \
              wifi-sec.key-mgmt wpa-psk \
              wifi-sec.psk "$WIFI_PASSWORD"
          else
            echo "WiFi connection $WIFI_SSID already exists, updating password..."
            nmcli connection modify "$WIFI_SSID" wifi-sec.psk "$WIFI_PASSWORD"
          fi

          echo "WiFi connection configured successfully"
        else
          echo "WiFi secrets not found, skipping WiFi setup"
        fi
      '';
    };

    # Extra hosts (commented out for now)
    networking.extraHosts = ''
      # Uncomment to block specific sites
      # 127.0.0.1 pinalove.com
      # 127.0.0.1 www.pinalove.com
      # 127.0.0.1 m.pinalove.com
      # 127.0.0.1 mobile.pinalove.com
    '';

    # Timezone
    time.timeZone = "America/Bahia_Banderas";

    # Disable network time synchronization (using default)
    services.timesyncd.enable = false;

    # Enable network discovery and printing services
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Firewall configuration
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };
}