{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "wolfram-jupyter-kernel";
  version = "v0.9.2";

  src = fetchFromGitHub {
    owner = "WolframResearch";
    repo = "WolframLanguageForJupyter";
    rev = version;
    sha256 = "19d9dvr0bv7iy0x8mk4f576ha7z7h7id39nyrggwf9cp7gymxf47";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir $out
    cp -r $src/WolframLanguageForJupyter/ $out/WolframLanguageForJupyter
  '';
}
