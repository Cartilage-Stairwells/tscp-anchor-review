#!/bin/bash
# Verify this review snapshot against Cartilage-Stairwells/tscp-anchor at the pinned commit.
# No credentials needed: the canonical repo is public.
#
#   ./verify-mirror.sh            manifest check only (offline, proves the clone is intact)
#   ./verify-mirror.sh --full     also fetches the canonical repo at the pin and compares content
#
# Exit 0 = this clone matches what it claims. Non-zero = it does not.
set -uo pipefail
export LC_ALL=C
PIN="c664991671f50ad5763c436ce73b30c1d0791a00"
CANON="https://github.com/Cartilage-Stairwells/tscp-anchor.git"
# Files that exist here and not in the canonical tree: the mirror's own apparatus.
OWN="MIRROR-NOTE.md verify-mirror.sh MIRROR-MANIFEST.sha256"
MANIFEST="MIRROR-MANIFEST.sha256"
MAXREPORT=20
fail=0
say() { printf '%s\n' "$*"; }
cap() { head -n "$MAXREPORT" | sed 's/^/     /'; }

[ -f "$MANIFEST" ] || { say "FAIL: $MANIFEST missing; run from the repository root"; exit 2; }

say "== 1. manifest: are these the bytes that were filed? =="
if sha256sum -c --quiet "$MANIFEST" 2>/tmp/mirror-manifest.err; then
  say "   OK  $(wc -l < "$MANIFEST") files verify against $MANIFEST"
else
  say "   FAIL  mismatches, missing, or unreadable:"; cap < /tmp/mirror-manifest.err; fail=1
fi

say "== 2. coverage: is any present file unlisted, any listed file absent from disk? =="
sed 's/^[0-9a-f]\{64\}  //' "$MANIFEST" | sort > /tmp/mirror-listed
absent=""
while IFS= read -r path; do [ -f "$path" ] || absent="$absent$path"$'\n'; done < /tmp/mirror-listed
git ls-files | grep -vx -- "$MANIFEST" | sort > /tmp/mirror-tracked
listed_not_tracked=$(comm -23 /tmp/mirror-listed /tmp/mirror-tracked)
unlisted_tracked=$(comm -13 /tmp/mirror-listed /tmp/mirror-tracked)
untracked=$(git ls-files --others --exclude-standard)
if [ -z "$absent" ] && [ -z "$listed_not_tracked" ] && [ -z "$unlisted_tracked" ] && [ -z "$untracked" ]; then
  say "   OK  $(wc -l < /tmp/mirror-listed) files listed, present on disk, and tracked here; no stray files (the manifest cannot list itself)"
else
  fail=1
  [ -n "$absent" ] && { say "   FAIL  listed but MISSING FROM DISK:"; printf '%s' "$absent" | cap; }
  [ -n "$listed_not_tracked" ] && { say "   FAIL  listed but not tracked in this clone:"; printf '%s\n' "$listed_not_tracked" | cap; }
  [ -n "$unlisted_tracked" ] && { say "   FAIL  tracked but not listed in the manifest:"; printf '%s\n' "$unlisted_tracked" | cap; }
  [ -n "$untracked" ] && { say "   FAIL  present on disk but not part of this snapshot:"; printf '%s\n' "$untracked" | cap; }
fi

[ "${1:-}" = "--full" ] || { say ""; [ $fail -eq 0 ] && say "RESULT: clone intact. Not compared with the canonical repo (pass --full)." || say "RESULT: FAILED."; exit $fail; }

say "== 3. content: does this tree equal tscp-anchor@${PIN:0:8}? =="
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if ! git -C "$tmp" init -q . || ! git -C "$tmp" fetch -q --depth 1 "$CANON" "$PIN"; then
  say "   CANNOT COMPARE: could not fetch the canonical repo at the pin"; exit 2
fi
git -C "$tmp" checkout -q FETCH_HEAD
git -C "$tmp" ls-tree -r HEAD > /tmp/mirror-canon-tree
identical=0; differs=""; missing=""; only_here=0
while IFS=$'\t' read -r meta path; do
  sha=${meta##* }
  if [ ! -f "$path" ]; then missing="$missing$path"$'\n'; continue; fi
  if [ "$(git hash-object -- "$path")" = "$sha" ]; then identical=$((identical+1)); else differs="$differs$path"$'\n'; fi
done < /tmp/mirror-canon-tree
while IFS= read -r path; do
  grep -qxF -- "$path" /tmp/mirror-canon-tree >/dev/null 2>&1 || \
  if ! awk -F'\t' -v p="$path" '$2==p{f=1} END{exit !f}' /tmp/mirror-canon-tree; then
    case " $OWN " in *" $path "*) ;; *) only_here=$((only_here+1)); say "   EXTRA HERE: $path";; esac
  fi
done < /tmp/mirror-present
say "   identical $identical | differing $(printf '%s' "$differs" | grep -c . ) | missing $(printf '%s' "$missing" | grep -c . ) | extra $only_here"
[ -n "$differs" ] && { say "   DIFFERS:"; printf '%s' "$differs" | cap; }
[ -n "$missing" ] && { say "   MISSING HERE:"; printf '%s' "$missing" | cap; }
n=$(printf '%s%s' "$differs" "$missing" | grep -c . ); [ "$n" -eq 0 ] && [ "$only_here" -eq 0 ] || fail=1

say ""
if [ $fail -eq 0 ]; then
  say "RESULT: PASS. Byte-identical to tscp-anchor@${PIN:0:8}, plus the three files named in MIRROR-NOTE.md."
else
  say "RESULT: FAILED. The canonical repo governs; do not cite this copy until it is regenerated."
fi
exit $fail
