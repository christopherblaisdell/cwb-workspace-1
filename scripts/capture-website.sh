#!/bin/zsh
# Captures a facility website for evidentiary use:
#   1. Raw HTML + HTTP response headers for each page
#   2. Extracted plain text for readability
#   3. SHA-256 hashes of everything (integrity verification)
#   4. Triggers an independent Wayback Machine archive and records the URL
#   5. Writes a manifest documenting method, tool versions, and timestamps
set -uo pipefail

BASE="https://www.remedytherapybehavioralhealth.com"
STAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
STAMP_LOCAL=$(date +"%Y-%m-%d %H:%M:%S %Z")
DATESTAMP=$(date +%Y-%m-%d)
OUT="${1:-$HOME/Documents/cwb-workspace-1/disputes/2026-08-28-behavioral-health-billing/evidence/${DATESTAMP}-website-capture}"

PAGES=(
  "/"
  "/treatments/"
  "/treatments/individual-therapy/"
  "/treatments/group-therapy/"
  "/treatments/residential-treatment/"
  "/treatments/detox/"
  "/treatments/family-therapy/"
  "/treatments/trauma-therapy/"
  "/treatments/medical-intervention/"
  "/about/our-team/"
  "/about/our-facility/"
  "/conditions/"
  "/admissions/verify-my-insurance/"
  "/privacy-policy/"
  "/hipaa-privacy-policy/"
  "/terms-of-use/"
)

mkdir -p "$OUT/html" "$OUT/headers" "$OUT/text"
MANIFEST="$OUT/CAPTURE-MANIFEST.md"

{
  echo "# Website Capture Manifest"
  echo ""
  echo "**Target:** \`$BASE\`  "
  echo "**Captured (local):** $STAMP_LOCAL  "
  echo "**Captured (UTC):** $STAMP_UTC  "
  echo "**Method:** \`curl\` direct HTTP retrieval, unmodified response bodies saved  "
  echo "**Operator:** Christopher Wayne Blaisdell  "
  echo "**Machine:** $(hostname)  "
  echo "**Tool:** $(curl --version | head -1)  "
  echo ""
  echo "Each page below was retrieved directly from the origin server. Raw HTML is stored"
  echo "in \`html/\`, HTTP response headers in \`headers/\`, and extracted plain text in"
  echo "\`text/\`. SHA-256 hashes are listed for integrity verification and are also written"
  echo "to \`SHA256SUMS.txt\`."
  echo ""
  echo "| # | Path | HTTP | Bytes | SHA-256 (HTML) |"
  echo "|---|------|------|-------|----------------|"
} > "$MANIFEST"

i=0
for p in "${PAGES[@]}"; do
  i=$((i+1))
  slug=$(echo "$p" | sed 's#^/##; s#/$##; s#/#_#g')
  [[ -z "$slug" ]] && slug="homepage"
  url="${BASE}${p}"

  code=$(curl -sS -L --max-time 45 \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36" \
    -D "$OUT/headers/${slug}.headers.txt" \
    -o "$OUT/html/${slug}.html" \
    -w "%{http_code}" "$url" 2>/dev/null)

  if [[ -f "$OUT/html/${slug}.html" ]]; then
    bytes=$(wc -c < "$OUT/html/${slug}.html" | tr -d ' ')
    hash=$(shasum -a 256 "$OUT/html/${slug}.html" | awk '{print $1}')
    # Strip tags for a readable text version.
    sed -e 's/<script[^>]*>.*<\/script>//g' -e 's/<style[^>]*>.*<\/style>//g' \
        -e 's/<[^>]*>//g' "$OUT/html/${slug}.html" \
      | sed -e 's/&nbsp;/ /g' -e 's/&amp;/\&/g' -e 's/&quot;/"/g' -e "s/&#8217;/'/g" \
      | grep -v '^[[:space:]]*$' > "$OUT/text/${slug}.txt" 2>/dev/null
  else
    bytes=0; hash="RETRIEVAL FAILED"
  fi

  printf '| %d | `%s` | %s | %s | `%s` |\n' "$i" "$p" "$code" "$bytes" "${hash:0:32}..." >> "$MANIFEST"
  echo "  [$code] $p  ($bytes bytes)"
done

cd "$OUT" && shasum -a 256 html/*.html text/*.txt headers/*.txt > SHA256SUMS.txt 2>/dev/null

echo ""
echo "Requesting independent Wayback Machine archives..."
{
  echo ""
  echo "## Independent Wayback Machine archives"
  echo ""
  echo "Save requests submitted $STAMP_UTC. Verify each at \`web.archive.org\`."
  echo ""
  echo "| Path | Wayback response |"
  echo "|------|------------------|"
} >> "$MANIFEST"

for p in "${PAGES[@]}"; do
  url="${BASE}${p}"
  wb=$(curl -sS -I --max-time 60 -A "Mozilla/5.0" "https://web.archive.org/save/${url}" 2>/dev/null \
        | grep -i -m1 -E '^(content-location|location):' | tr -d '\r' | sed 's/^[^:]*: *//')
  [[ -z "$wb" ]] && wb="submitted (verify manually)"
  printf '| `%s` | %s |\n' "$p" "$wb" >> "$MANIFEST"
  echo "  $p -> $wb"
done

{
  echo ""
  echo "## Verification"
  echo ""
  echo "\`\`\`sh"
  echo "cd \"$OUT\" && shasum -a 256 -c SHA256SUMS.txt"
  echo "\`\`\`"
  echo ""
  echo "## Note on evidentiary weight"
  echo ""
  echo "This capture was made by the complainant on his own machine. It is authentic and"
  echo "hash-verified, but it is self-collected. The Wayback Machine archives listed above"
  echo "are captured and timestamped by an independent third party and carry more weight."
  echo "Both should be preserved. Neither substitutes for the originals being produced by"
  echo "the facility in discovery."
} >> "$MANIFEST"

echo ""
echo "Capture complete: $OUT"
