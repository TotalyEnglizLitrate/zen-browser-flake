{
  description = "Zen Browser - Performance-oriented Firefox-based web browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    mkSources = {
      version,
      isExperimental ? false,
    }: {
      x86_64-linux = {
        url = "https://github.com/zen-browser/desktop/releases/download/${
          if isExperimental
          then "twilight"
          else version
        }/zen.linux-x86_64.tar.${
          if isExperimental
          then "xz"
          else "bz2"
        }";
        hash = "sha256-${
          if isExperimental
          then "jTO8RUlDde9k9FJJIdhF2QTiH0KKAKA0V3Crkn3CA/4="
          else "p4UQg4zQaqJ4DOed0wXBOSg0HPz4fwqbXZtPuw0+S48="
        }";
      };
      aarch64-linux = {
        url = "https://github.com/zen-browser/desktop/releases/download/${
          if isExperimental
          then "twilight"
          else version
        }/zen.linux-aarch64.tar.${
          if isExperimental
          then "xz"
          else "bz2"
        }";
        hash = "sha256-${
          if isExperimental
          then "CbT9WvjpHZxtX4/Ooje97F1UM9NFLv1p212NaOKpHv4="
          else "LriVX7eQ2x9twi1ncB2lZkUo+RaAC8TqTWThUO+1opA="
        }";
      };
    };

    versions = {
      stable = {
        version = "1.7.4b";
        sources = mkSources {version = "1.7.4b";};
      };
      experimental = {
        version = "1.7.4t";
        sources = mkSources {
          version = "1.7.4t";
          isExperimental = true;
        };
      };
    };

    desktopFile = ''
      [Desktop Entry]
      Name=Zen Browser
      Comment=Experience tranquillity while browsing the web without people tracking you!
      Exec=zen-browser %u
      Icon=zen-browser
      Type=Application
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;application/pdf;application/json;
      StartupWMClass=zen
      Categories=Network;WebBrowser;
      StartupNotify=true
      Terminal=false
      X-MultipleArgs=false
      Keywords=Internet;WWW;Browser;Web;Explorer;
      Actions=new-window;new-private-window;profilemanager;

      [Desktop Action new-window]
      Name=Open a New Window
      Exec=zen-browser %u

      [Desktop Action new-private-window]
      Name=Open a New Private Window
      Exec=zen-browser --private-window %u

      [Desktop Action profilemanager]
      Name=Open the Profile Manager
      Exec=zen-browser --ProfileManager %u
    '';
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      mkZen = {variant ? "stable"}: let
        variantData = versions.${variant};
      in
        pkgs.stdenv.mkDerivation {
          pname = "zen-browser";
          version = variantData.version;
          src = pkgs.fetchurl variantData.sources.${system};

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
            pkgs.copyDesktopItems
            pkgs.glib
          ];

          buildInputs = with pkgs;
            [
              libGL
              libGLU
              libevent
              libffi
              libjpeg
              libpng
              libstartup_notification
              libvpx
              libwebp
              stdenv.cc.cc
              fontconfig
              libxkbcommon
              zlib
              freetype
              gtk3
              libxml2
              dbus
              xcb-util-cursor
              alsa-lib
              libpulseaudio
              pango
              atk
              cairo
              gdk-pixbuf
              glib
              udev
              libva
              mesa
              libnotify
              cups
              pciutils
              ffmpeg
              libglvnd
              pipewire
              gsettings-desktop-schemas
              gtk3
            ]
            ++ (with pkgs.xorg; [
              libxcb
              libX11
              libXcursor
              libXrandr
              libXi
              libXext
              libXcomposite
              libXdamage
              libXfixes
              libXScrnSaver
            ]);

          sourceRoot = ".";
          dontBuild = true;
          dontConfigure = true;

          installPhase = ''
            set -e

            mkdir -p $out/bin
            mkdir -p $out/share/applications
            mkdir -p $out/share/icons/hicolor

            # Install browser files
            cp -r zen/ $out/

            # Create wrapper script pointing to the correct executable
            makeWrapper $out/zen/zen $out/bin/zen-browser \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath (with pkgs; [
              gtk3
              xorg.libXt
              dbus-glib
              nss
              fontconfig
              systemd
              libnotify
              speechd
              hunspell
              ffmpeg
              libglvnd
            ])}

            # Install desktop file
            echo "${desktopFile}" > $out/share/applications/zen-browser.desktop

            # Install icons
            for i in 16 32 48 64 128; do
              size=$i"x"$i
              mkdir -p $out/share/icons/hicolor/$size/apps
              ln -s $out/zen/browser/chrome/icons/default/default$i.png \
                    $out/share/icons/hicolor/$size/apps/zen-browser.png
            done

            # Use system dictionaries and certificates
            ln -Ts ${pkgs.hunspellDicts.en_US}/share/hunspell $out/zen/dictionaries
            ln -Ts ${pkgs.hyphen}/share/hyphen $out/zen/hyphenation
            ln -sf ${pkgs.nss}/lib/libnssckbi.so $out/zen/libnssckbi.so

            # Disable updates
            mkdir -p $out/zen/distribution
            echo '{"policies": {"DisableAppUpdate": true}}' > $out/zen/distribution/policies.json
          '';

          postInstall = ''
            # Install GSettings schemas
            mkdir -p $out/share/gsettings-schemas/zen-browser
            cp -r ${pkgs.gsettings-desktop-schemas}/share/glib-2.0/schemas $out/share/gsettings-schemas/zen-browser/

            # Ensure GSettings schemas are compiled and recognized
            ${pkgs.glib}/bin/glib-compile-schemas $out/share/gsettings-schemas/zen-browser/schemas

            # Modify wrapper to include GSettings path
            wrapProgram $out/bin/zen-browser \
              --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/zen-browser:${pkgs.gsettings-desktop-schemas}/share"
          '';

          meta = with pkgs.lib; {
            description =
              "Performance-oriented Firefox-based web browser"
              + (
                if variant == "experimental"
                then " (Experimental Build)"
                else ""
              );
            homepage = "https://github.com/zen-browser/desktop";
            license = licenses.mpl20;
            platforms = supportedSystems;
          };
        };
    in {
      stable = mkZen {variant = "stable";};
      experimental = mkZen {variant = "experimental";};
      default = self.packages.${system}.stable;
    });
  };
}
