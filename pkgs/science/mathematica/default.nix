{ lib, stdenv, runCommand, buildFHSUserEnv, requireFile, coreutils, patchelf
, callPackage, makeWrapper, alsaLib, dbus, dbus_libs, fontconfig, freetype, gcc
, glib, libssh2, ncurses, opencv4, openssl, unixODBC, xkeyboard_config, xorg
, zlib, libxml2, libuuid, libGL, libGLU }:

let
  mathematica = stdenv.mkDerivation rec {
    version = "12.2.0";
    name = "mathematica";
    src = requireFile rec {
      name = "Mathematica_${version}_LINUX.sh";
      message = ''
        This nix expression requires that ${name} is
        already part of the store. Find the file on your Mathematica CD
        and add it to the nix store with nix-store --add-fixed sha256 <FILE>.
      '';
      sha256 = "006zrhhsq5wzvps614l5y9nbgx77gq8kfv69iq00bzmzg8l79nmx";
    };

    buildInputs = [
      coreutils
      patchelf
      makeWrapper
      alsaLib
      coreutils
      dbus
      fontconfig
      freetype
      gcc.cc
      gcc.libc
      glib
      libssh2
      ncurses
      opencv4
      openssl
      stdenv.cc.cc.lib
      unixODBC
      xkeyboard_config
      libxml2
      libuuid
      zlib
      libGL
      libGLU
    ] ++ (with xorg; [
      libX11
      libXext
      libXtst
      libXi
      libXmu
      libXrender
      libxcb
      libXcursor
      libXfixes
      libXrandr
      libICE
      libSM
    ]);

    ldpath = lib.makeLibraryPath buildInputs
      + lib.optionalString (stdenv.hostPlatform.system == "x86_64-linux")
      (":" + lib.makeSearchPathOutput "lib" "lib64" buildInputs);

    unpackPhase = ''
      echo "=== Extracting makeself archive ==="
      # find offset from file
      offset=$(${stdenv.shell} -c "$(grep -axm1 -e 'offset=.*' $src); echo \$offset" $src)
      dd if="$src" ibs=$offset skip=1 | tar -xf -
      cd Unix
    '';

    installPhase = ''
      cd Installer
      # don't restrict PATH, that has already been done
      sed -i -e 's/^PATH=/# PATH=/' MathInstaller
      sed -i -e 's/\/bin\/bash/\/bin\/sh/' MathInstaller
      echo "=== Running MathInstaller ==="
      ./MathInstaller -auto -createdir=y -execdir=$out/bin -targetdir=$out/libexec/Mathematica -silent
      # Fix library paths
      cd $out/libexec/Mathematica/Executables
      for path in mathematica MathKernel Mathematica WolframKernel wolfram math; do
        sed -i -e "2iexport LD_LIBRARY_PATH=${zlib}/lib:${stdenv.cc.cc.lib}/lib:${libssh2}/lib:\''${LD_LIBRARY_PATH}\n" $path
      done
      # Fix xkeyboard config path for Qt
      for path in mathematica Mathematica; do
        sed -i -e "2iexport QT_XKB_CONFIG_ROOT=\"${xkeyboard_config}/share/X11/xkb\"\n" $path
      done
      # Remove some broken libraries
      rm -f $out/libexec/Mathematica/SystemFiles/Libraries/Linux-x86-64/libz.so*
      # Set environment variable to fix libQt errors - see https://github.com/NixOS/nixpkgs/issues/96490
      wrapProgram $out/bin/mathematica --set USE_WOLFRAM_LD_LIBRARY_PATH 1
    '';

    preFixup = ''
      echo "=== PatchElfing away ==="
      # This code should be a bit forgiving of errors, unfortunately
      set +e
      find $out/libexec/Mathematica/SystemFiles -type f -perm -0100 | while read f; do
        type=$(readelf -h "$f" 2>/dev/null | grep 'Type:' | sed -e 's/ *Type: *\([A-Z]*\) (.*/\1/')
        if [ -z "$type" ]; then
          :
        elif [ "$type" == "EXEC" ]; then
          echo "patching $f executable <<"
          patchelf --shrink-rpath "$f"
          patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
            --set-rpath "$(patchelf --print-rpath "$f"):${ldpath}" \
            "$f" \
            && patchelf --shrink-rpath "$f" \
            || echo unable to patch ... ignoring 1>&2
        elif [ "$type" == "DYN" ]; then
          echo "patching $f library <<"
          patchelf \
            --set-rpath "$(patchelf --print-rpath "$f"):${ldpath}" \
            "$f" \
            && patchelf --shrink-rpath "$f" \
            || echo unable to patch ... ignoring 1>&2
        else
          echo "not patching $f <<: unknown elf type"
        fi
      done
    '';

    dontBuild = true;

    # This is primarily an IO bound build; there's little benefit to building remotely.
    preferLocalBuild = true;

    # all binaries are already stripped
    dontStrip = true;

    # we did this in prefixup already
    dontPatchELF = true;
  };

  env = buildFHSUserEnv {
    name = "${mathematica.name}-env";
    targetPkgs = pkgs': [ mathematica dbus_libs ];
    runScript = "";
  };
in runCommand mathematica.name { nativeBuildInputs = [ makeWrapper ]; } ''
  mkdir -p "$out/bin"
  mkdir -p "$out/share/applications"
  mkdir -p "$out/share/icons/hicolor/32x32/apps"
  mkdir -p "$out/share/icons/hicolor/64x64/apps"
  mkdir -p "$out/share/icons/hicolor/128x128/apps"
  for i in "${mathematica}/libexec/Mathematica/Executables/"* "${mathematica}/libexec/Mathematica/SystemFiles/Kernel/Binaries/Linux-x86-64/"*; do
    base="$(basename "$i")"
    echo "Wrapping $base"
    makeWrapper ${env}/bin/${env.name} "$out/bin/$base" --add-flags "$i"
  done
  cp ${mathematica}/libexec/Mathematica/SystemFiles/Installation/wolfram-mathematica12.desktop $out/share/applications/
  substituteInPlace $out/share/applications/wolfram-mathematica12.desktop --replace "${mathematica}/libexec/Mathematica/Executables/Mathematica" $out/bin/Mathematica

  cp ${mathematica}/libexec/Mathematica/SystemFiles/FrontEnd/SystemResources/X/App-32.png $out/share/icons/hicolor/32x32/apps/wolfram-mathematica.png
  cp ${mathematica}/libexec/Mathematica/SystemFiles/FrontEnd/SystemResources/X/App-64.png $out/share/icons/hicolor/64x64/apps/wolfram-mathematica.png
  cp ${mathematica}/libexec/Mathematica/SystemFiles/FrontEnd/SystemResources/X/App-128.png $out/share/icons/hicolor/128x128/apps/wolfram-mathematica.png
''
