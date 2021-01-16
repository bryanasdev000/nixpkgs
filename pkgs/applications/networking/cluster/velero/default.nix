{ lib, stdenv, buildGoModule, fetchFromGitHub, installShellFiles }:

buildGoModule rec {
  pname = "velero";
  version = "1.5.3";

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "vmware-tanzu";
    repo = "velero";
    sha256 = "1pjpvkk8ff5285cv0qk4ki8ajgyy997lf11b155pzwjwkj2ak7hd";
  };

  buildFlagsArray = ''
    -ldflags=
      -s -w
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.Version=${version}
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.GitSHA=123109a3bcac11dbb6783d2758207bac0d0817cb
      -X github.com/vmware-tanzu/velero/pkg/buildinfo.GitTreeState=clean
  '';

  vendorSha256 = "1izl7z689jf3i3wax7rfpk0jjly7nsi7vzasy1j9v5cwjy2d5z4v";

  excludedPackages = [ "issue-template-gen" ];

  doCheck = false;

  nativeBuildInputs = [ installShellFiles ];
  postInstall = ''
    $out/bin/velero completion bash > velero.bash
    $out/bin/velero completion zsh > velero.zsh
    installShellCompletion velero.{bash,zsh}
  '';

  meta = with lib; {
    description =
      "A utility for managing disaster recovery, specifically for your Kubernetes cluster resources and persistent volumes";
    homepage = "https://velero.io/";
    changelog =
      "https://github.com/vmware-tanzu/velero/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = [ maintainers.mbode maintainers.bryanasdev000 ];
    platforms = platforms.linux;
  };
}
