{
  lib,
  makeWrapper,
  symlinkJoin,
  tinycc,
  kak-tree-sitter-unwrapped,
  callPackage,
}:

let
  languagesLib = callPackage ./languages {
    configFile = "${kak-tree-sitter-unwrapped.src}/kak-tree-sitter-config/default-config.toml";
  };
in
symlinkJoin (finalAttrs: {
  pname = lib.replaceStrings [ "-unwrapped" ] [ "" ] kak-tree-sitter-unwrapped.pname;
  inherit (kak-tree-sitter-unwrapped) version;
  name = "${finalAttrs.pname}-${finalAttrs.version}";

  paths = [ kak-tree-sitter-unwrapped ];
  nativeBuildInputs = [ makeWrapper ];

  # Tree-Sitter grammars are C programs that need to be compiled
  # Use tinycc as cc to reduce closure size
  postBuild = ''
    mkdir -p $out/libexec/tinycc/bin
    ln -s ${lib.getExe tinycc} $out/libexec/tinycc/bin/cc
    wrapProgram "$out/bin/ktsctl" \
      --suffix PATH : $out/libexec/tinycc/bin
  '';

  passthru = {
    inherit (languagesLib) grammars languages localConfig mkLocalConfig;
  };

  inherit (kak-tree-sitter-unwrapped) meta;
})
