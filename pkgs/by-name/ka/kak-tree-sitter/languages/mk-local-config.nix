{ lib, writers }:
let
  sortNames = names: lib.sort lib.lessThan (lib.attrNames names);
in
{
  grammars ? { },
  queries ? { },
}:
writers.writeTOML "kak-tree-sitter-local-config" {
  grammar = lib.genAttrs (sortNames grammars) (name: {
    source.local.path = grammars.${name};
  });
  language = lib.genAttrs (sortNames queries) (name: {
    queries.source.local.path = queries.${name};
  });
}
