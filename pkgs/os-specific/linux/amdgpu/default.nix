{ stdenv
, fetchpatch
, linuxPackages
, kernel ? linuxPackages.kernel
}:

stdenv.mkDerivation {
  name = "amdgpu-${kernel.version}-module-${kernel.modDirVersion}";

  kernel = kernel.dev;
  kernelVersion = kernel.modDirVersion;

  version = kernel.version;
  src = kernel.src;

  postUnpack = ''
    cd */usr/src
    sourceRoot="$(pwd -P)"
  '';

  buildPhase = ''
    cd $sourceRoot/blackmagic-''${version}*/
    # missing some "touch" commands, make sure they exist for build.
    make -C $kernel/lib/modules/$kernelVersion/build modules "M=$(pwd -P)"

    cd $sourceRoot/blackmagic-io-''${version}*/
    # missing some "touch" commands, make sure they exist for build.
    touch .blackmagic.o.cmd
    make -C $kernel/lib/modules/$kernelVersion/build modules "M=$(pwd -P)"

    cd $sourceRoot
  '';

  installPhase = ''
    mkdir -p $out/lib/modules/$kernelVersion/misc
    for x in $(find . -name '*.ko'); do
      cp $x $out/lib/modules/$kernelVersion/misc/
    done
  '';

  meta.platforms = [ "x86_64-linux" ];
}
