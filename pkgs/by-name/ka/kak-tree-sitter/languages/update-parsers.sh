#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bash yq nix-prefetch-git jq

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSERS_JSON="$ROOT/parsers.json"

if [[ -n "${KAK_TREE_SITTER_CONFIG:-}" ]]; then
  CONFIG="$KAK_TREE_SITTER_CONFIG"
else
  SRC="$(nix-build --no-out-link -A kak-tree-sitter-unwrapped.src)"
  CONFIG="$SRC/kak-tree-sitter-config/default-config.toml"
fi

tomlq -r '.. | select(objects and (.git | objects)) | "\(.git.url) \(.git.pin)"' "$CONFIG" \
| sort -u \
| while read -r url rev; do
    url="${url/http:\/\/github.com/https://github.com}"
    nix-prefetch-git --no-add-path "$url" "$rev" \
    | jq --arg url "$url" --arg rev "$rev" '{ url: $url, rev: $rev, hash: .hash }'
  done \
| jq -s 'map({key: "\(.url) \(.rev)", value: .hash}) | from_entries' \
> "$ROOT/.update-parsers-hashes.json"

tomlq --slurpfile hashes "$ROOT/.update-parsers-hashes.json" '
$hashes[0] as $hashmap
| {
    grammar: .grammar
      | with_entries(select(.value.source != null and .value.source.git != null)
        | .value = .value.source.git
        | .value.url = (.value.url | sub("^http://github.com"; "https://github.com"))
        | .value.hash = $hashmap["\(.value.url) \(.value.pin)"]
      ),
    queries: .language
      | with_entries(select(.value.queries != null and .value.queries.source != null and .value.queries.source.git != null)
        | .value = .value.queries.source.git
        | .value.url = (.value.url | sub("^http://github.com"; "https://github.com"))
        | .value.hash = $hashmap["\(.value.url) \(.value.pin)"]
      )
}' "$CONFIG" > "$PARSERS_JSON"

rm "$ROOT/.update-parsers-hashes.json"
