{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "ddosify";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-QzNMUeA9oOZaNZDGf9TXloZ5r2prDHTRX1wso3fSetc=";
  };

  vendorSha256 = "sha256-TY8shTb77uFm8/yCvlIncAfq7brWgnH/63W+hj1rvqg=";

  ldflags = [
    "-s -w"
    "-X main.GitVersion=${version}"
  ];

  # try to acess wikipedia for testing
  #json_test.go:222: TestCreateHammerMultipartPayload error occurred: Get "https://upload.wikimedia.org/wikipedia/commons/b/bd/Test.svg":
  #dial tcp: lookup upload.wikimedia.org on [::1]:53: read udp [::1]:39097->[::1]:53: read: connection refused

  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/ddosify -version | grep ${version} > /dev/null
  '';

  meta = with lib; {
    description = "High-performance load testing tool, written in Golang";
    homepage = "https://ddosify.com/";
    changelog = "https://github.com/ddosify/ddosify/releases/tag/v${version}";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ bryanasdev000 ];
  };
}
