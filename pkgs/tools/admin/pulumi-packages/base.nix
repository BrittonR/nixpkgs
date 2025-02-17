{ buildGoModule
, fetchFromGitHub
, python3Packages
}:
let
  mkBasePackage =
    { pname
    , src
    , version
    , vendorHash
    , cmd
    , extraLdflags
    , ...
    }@args: buildGoModule (rec {
      inherit pname src vendorHash version;

      sourceRoot = "${src.name}/provider";

      subPackages = [ "cmd/${cmd}" ];

      doCheck = false;

      ldflags = [
        "-s"
        "-w"
      ] ++ extraLdflags;

      # scripts/upstream.sh and Makefile have unwanted dependencies. Just apply
      # patches manually if needed.
      postPatch = ''
        pushd ..
        if [ -d upstream -a -d patches ]; then
          chmod -R +w upstream
          for patch in patches/*.patch; do
            echo "Applying $patch"
            patch -p1 -d upstream <"$patch"
          done
        fi
        popd
      '';
    } // args);

  mkPythonPackage =
    { meta
    , pname
    , src
    , version
    , ...
    }: python3Packages.callPackage
      ({ buildPythonPackage, pythonOlder, parver, pulumi, semver }:
      buildPythonPackage rec {
        inherit pname meta src version;
        format = "setuptools";

        disabled = pythonOlder "3.7";

        sourceRoot = "${src.name}/sdk/python";

        propagatedBuildInputs = [
          parver
          pulumi
          semver
        ];

        postPatch = ''
          sed -i \
            -e 's/^VERSION = .*/VERSION = "${version}"/g' \
            -e 's/^PLUGIN_VERSION = .*/PLUGIN_VERSION = "${version}"/g' \
            setup.py
        '';

        # Auto-generated; upstream does not have any tests.
        # Verify that the version substitution works
        checkPhase = ''
          runHook preCheck

          pip show "${pname}" | grep "Version: ${version}" > /dev/null \
            || (echo "ERROR: Version substitution seems to be broken"; exit 1)

          runHook postCheck
        '';

        pythonImportsCheck = [
          (builtins.replaceStrings [ "-" ] [ "_" ] pname)
        ];
      })
      { };
in
{ owner
, repo
, rev
, version
, hash
, vendorHash
, cmdGen
, cmdRes
, extraLdflags
, meta
, fetchSubmodules ? false
, ...
}@args:
let
  src = fetchFromGitHub {
    name = "source-${repo}-${rev}";
    inherit owner repo rev hash fetchSubmodules;
  };

  pulumi-gen = mkBasePackage rec {
    inherit src version vendorHash extraLdflags;

    cmd = cmdGen;
    pname = cmdGen;
  };
in
mkBasePackage ({
  inherit meta src version vendorHash extraLdflags;

  pname = repo;

  nativeBuildInputs = [
    pulumi-gen
  ];

  cmd = cmdRes;

  postConfigure = ''
    pushd ..

    chmod +w sdk/
    ${cmdGen} schema

    popd

    VERSION=v${version} go generate cmd/${cmdRes}/main.go
  '';

  passthru.sdks.python = mkPythonPackage {
    inherit meta src version;

    pname = repo;
  };
} // args)
