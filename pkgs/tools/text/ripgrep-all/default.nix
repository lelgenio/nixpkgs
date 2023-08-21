{ stdenv
, lib
, fetchFromGitHub
, rustPlatform
, makeWrapper
, ffmpeg
, pandoc
, poppler_utils
, ripgrep
, Security
, imagemagick
, tesseract3
}:

let
  runtimeDeps = [
    ffmpeg
    pandoc
    poppler_utils
    ripgrep
    imagemagick
    tesseract3
  ];
in
rustPlatform.buildRustPackage rec {
  pname = "ripgrep-all";
  version = "1.0.0-alpha.5";

  src = fetchFromGitHub {
    owner = "phiresky";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-fpDYzn4oAz6GJQef520+Vi2xI09xFjpWdAlFIAVzcoA=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "tokio-tar-0.3.1" = "sha256-gp4UM6YV7P9k1FZxt3eVjyC4cK1zvpMjM5CPt2oVBEA=";
    };
  };
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = runtimeDeps ++ lib.optional stdenv.isDarwin Security;

  preCheck = ''
    export PATH="$PATH:${lib.makeBinPath runtimeDeps}"
  '';

  postInstall = ''
    wrapProgram $out/bin/rga \
      --prefix PATH ":" "${lib.makeBinPath runtimeDeps}"
    wrapProgram $out/bin/rga-preproc \
      --prefix PATH ":" "${lib.makeBinPath runtimeDeps}"
  '';

  # Use upstream's example data to run a couple of queries to ensure the dependencies
  # for all of the adapters are available.
  installCheckPhase = ''
    set -e
    export PATH="$PATH:$out/bin"

    RGA_ARGS="--rga-config-file=doc/config.default.jsonc --rga-cache-path=$(mktemp -d)"
    test1=$(rga $RGA_ARGS "hello" exampledir/ | wc -l)
    test2=$(rga $RGA_ARGS "crate" exampledir/screenshot.png | wc -l)

    if [ $test1 != 26 ]
    then
      echo "ERROR: test1 failed! Could not find the word 'hello' 26 times in the sample data."
      exit 1
    fi

    if [ $test2 != 1 ]
    then
      echo "ERROR: test2 failed! Could not find the word 'crate' in the screenshot."
      exit 1
    fi
  '';

  doInstallCheck = true;

  meta = with lib; {
    description = "Ripgrep, but also search in PDFs, E-Books, Office documents, zip, tar.gz, and more";
    longDescription = ''
      Ripgrep, but also search in PDFs, E-Books, Office documents, zip, tar.gz, etc.

      rga is a line-oriented search tool that allows you to look for a regex in
      a multitude of file types. rga wraps the awesome ripgrep and enables it
      to search in pdf, docx, sqlite, jpg, movie subtitles (mkv, mp4), etc.
    '';
    homepage = "https://github.com/phiresky/ripgrep-all";
    license = with licenses; [ agpl3Plus ];
    maintainers = with maintainers; [ zaninime ma27 ];
    mainProgram = "rga";
  };
}
