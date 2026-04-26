final: prev: {
  cli-proxy-api = final.buildGoModule {
    pname = "cli-proxy-api";
    version = "6.7.23";

    src = final.fetchFromGitHub {
      owner = "router-for-me";
      repo = "CLIProxyAPI";
      rev = "v6.7.23";
      hash = "sha256-XEsUyP9caampyLgMMCH8pMJVM5k3Ghdg+v7ye9dxClk=";
    };

    subPackages = [ "cmd/server" ];
    vendorHash = "sha256-TiHP7roqb990zyN7htDha4bFvl7rufAA17UtlPJew3E=";

    postInstall = ''
      if [ -e "$out/bin/server" ]; then
        mv "$out/bin/server" "$out/bin/cli-proxy-api"
      fi
    '';

    ldflags = [
      "-s"
      "-w"
      "-X github.com/router-for-me/CLIProxyAPI/v6/internal/buildinfo.Version=6.7.23"
    ];

    meta = with final.lib; {
      description = "CLIProxyAPI server for Amp and other AI CLIs";
      homepage = "https://github.com/router-for-me/CLIProxyAPI";
      license = licenses.mit;
      mainProgram = "cli-proxy-api";
      platforms = platforms.unix;
    };
  };
}
