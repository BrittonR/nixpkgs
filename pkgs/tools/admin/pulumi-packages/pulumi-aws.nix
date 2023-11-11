{ lib
, mkPulumiPackage
}:
mkPulumiPackage rec {
  owner = "pulumi";
  repo = "pulumi-aws";
  version = "6.8.0";
  rev = "v${version}";
  hash = "sha256-8Lxro6Y4h+jG3eITicddTCfBbM1YyA/5ti+c7DMYB3c=";
  vendorHash = "sha256-+FZC0rvgCgS4snJ0Ln4IcYjs1RKyR4XbMA2NiBX03K8=";
  fetchSubmodules = true;
  cmdGen = "pulumi-tfgen-aws";
  cmdRes = "pulumi-resource-aws";
  extraLdflags = [
    "-X github.com/pulumi/${repo}/provider/v6/pkg/version.Version=v${version}"
  ];
  __darwinAllowLocalNetworking = true;
  meta = with lib; {
    description = "An Amazon Web Services (AWS) Pulumi resource package, providing multi-language access to AWS";
    homepage = "https://github.com/pulumi/pulumi-aws";
    license = licenses.asl20;
    maintainers = with maintainers; [ veehaitch trundle ];
    mainProgram = "pulumi-resource-aws";
  };
}
