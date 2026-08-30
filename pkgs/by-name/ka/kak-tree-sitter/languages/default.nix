{
  lib,
  fetchgit,
  callPackage,
  configFile,
  parsersJson ? ./parsers.json,
}:

let
  config = lib.importTOML configFile;
  parserSources = lib.importJSON parsersJson;

  mkGrammar = callPackage ./mk-grammar.nix {
    inherit configFile;
  };

  mkLanguage = callPackage ./mk-language.nix {
    inherit configFile;
  };

  getSrc =
    info:
    fetchgit {
      url = lib.replaceStrings [ "http://github.com" ] [ "https://github.com" ] info.url;
      hash = info.hash;
      rev = info.pin;
      fetchSubmodules = false;
    };

  grammarForLanguage = lang: config.language.${lang}.grammar or lang;

  grammarNames = lib.subtractLists [ "astro" ] (
    lib.intersectLists (lib.attrNames config.grammar) (lib.attrNames parserSources.grammar)
  );

  languageNames = lib.subtractLists [ "astro" ] (lib.attrNames parserSources.queries);

  grammars = lib.genAttrs grammarNames (
    lang:
    mkGrammar {
      inherit lang;
      grammarSrc = getSrc parserSources.grammar.${lang};
    }
  );

  languages = lib.genAttrs languageNames (
    lang:
    mkLanguage {
      inherit lang;
      grammar = grammars.${grammarForLanguage lang};
      queriesSrc = getSrc parserSources.queries.${lang};
    }
  );

  mkLocalConfig = callPackage ./mk-local-config.nix { };

  localConfig = mkLocalConfig {
    grammars = lib.mapAttrs (_: drv: "${drv}/parser") grammars;
    queries = lib.mapAttrs (_: drv: "${drv}/queries") languages;
  };

in
{
  inherit grammars languages localConfig mkLocalConfig;
}
