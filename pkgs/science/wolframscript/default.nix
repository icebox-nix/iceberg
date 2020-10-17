{ stdenv, autoPatchelfHook, dpkg }:

stdenv.mkDerivation rec {
  version = "12.1.1";
  pname = "wolframscript";
  src = ./WolframScript_12.1.1_LINUX64_amd64.deb;
  unpackCmd = "${dpkg}/bin/dpkg -x $src .";
  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    install -D -m755 ./opt/Wolfram/WolframScript/bin/wolframscript $out/bin/wolframscript
  '';

  dontBuild = true;
}
