{
  runCommandCC,
  yq,
  configFile,
}:
{
  lang,
  grammarSrc,
}:

assert grammarSrc != null;

runCommandCC "tree-sitter-${lang}"
  {
    nativeBuildInputs = [ yq ];
    passthru = {
      inherit lang;
    };
  }
  ''
    cp -r ${grammarSrc} grammar
    chmod -R u+w grammar

    grammar_path="$(tomlq -r '.grammar["${lang}"].path? // "src"' "${configFile}")"
    build_dir="grammar/$grammar_path/build"
    compile="$(tomlq -r '.grammar["${lang}"].compile? // "cc"' "${configFile}")"
    compile_args="$(tomlq -r '.grammar["${lang}"].compile_args? // ["-c", "-fpic", "../parser.c", "-I", ".."] | join(" ")' "${configFile}")"
    compile_flags="$(tomlq -r '.grammar["${lang}"].compile_flags? // ["-O3"] | join(" ")' "${configFile}")"
    link="$(tomlq -r '.grammar["${lang}"].link? // "cc"' "${configFile}")"
    link_args="$(tomlq -r '.grammar["${lang}"].link_args? // ["-shared", "-fpic", "parser.o", "-o", "${lang}.so"] | join(" ")' "${configFile}")"
    link_flags="$(tomlq -r '.grammar["${lang}"].link_flags? // ["-O3"] | join(" ")' "${configFile}")"

    mkdir -p "$build_dir"
    (
      cd "$build_dir"
      "$compile" $compile_args $compile_flags
      "$link" $link_args $link_flags
    )

    mkdir -p $out
    cp "$build_dir/${lang}.so" "$out/parser"

    if [[ -f grammar/tree-sitter.json ]]; then
      cp grammar/tree-sitter.json "$out/"
    elif [[ -f "grammar/$grammar_path/tree-sitter.json" ]]; then
      cp "grammar/$grammar_path/tree-sitter.json" "$out/"
    fi
  ''
