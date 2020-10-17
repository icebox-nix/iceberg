{ stdenv, fetchurl, autoPatchelfHook, unzip, zlib }:

stdenv.mkDerivation rec {
  pname = "fawkes";
  version = "v0.3";

  src = fetchurl {
    url =
      "https://mirror.cs.uchicago.edu/${pname}/files/fawkes_binary_linux-${version}.zip";
    sha256 = "1a5gcjmqc6yl5w3m919krjvjc636nk6j4djr3iq6wzxr2gzdga24";
  };

  nativeBuildInputs = [ unzip autoPatchelfHook ];

  buildInputs = [ zlib ];

  installPhase = ''
    mkdir -p $out/bin/
    install -D -m755 ../protection-${version} $out/bin/fawkes
  '';
}
