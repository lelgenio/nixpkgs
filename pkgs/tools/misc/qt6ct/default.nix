{
  stdenv,
  lib,

  fetchFromGitHub,

  cmake,
  wrapQtAppsHook,
  symlinkJoin,

  qtbase,
  qttools,
  qtsvg
}:
stdenv.mkDerivation rec {
  pname = "qt6ct";
  version = "0.7";

  src = fetchFromGitHub {
    owner = "trialuser02";
    repo = "qt6ct";
    rev = version;
    sha256 = "sha256-7WuHdb7gmdC/YqrPDT7OYbD6BEm++EcIkmORW7cSPDE=";
  };

  # the build system tries to detect it with qtpaths, but that does not work on NixOS
  patches = [ ./fix-qtpaths.diff ];
  cmakeFlags = [ "-DPLUGINDIR=${placeholder "out"}/${qtbase.qtPluginPrefix}" ];

  nativeBuildInputs = [ cmake wrapQtAppsHook qttools ];
  buildInputs = [ qtbase qtsvg ];

  meta = with lib; {
    description = "Qt6 Configuration Tool";
    homepage = "https://github.com/trialuser02/qt6ct";
    platforms = platforms.linux;
    license = licenses.bsd2;
    maintainers = with maintainers; [ k900 ];
  };
}
