{
  runCommand,
  yq,
  configFile,
}:
{
  lang,
  grammar,
  queriesSrc,
}:

runCommand "tree-sitter-${lang}"
  {
    nativeBuildInputs = [ yq ];
    passthru = {
      inherit lang;
      queries = "queries";
    };
  }
  ''
    queries_subpath="$(tomlq -r '.language["${lang}"].queries?.path? // "runtime/queries/${lang}"' "${configFile}")"
    mkdir -p $out/queries
    cp -r "${queriesSrc}/$queries_subpath/." $out/queries/
    ln -s ${grammar}/parser $out/parser
    if [[ -f ${grammar}/tree-sitter.json ]]; then
      ln -s ${grammar}/tree-sitter.json $out/
    fi
  ''
