#!/usr/bin/env bash
# Swap the patched axi_dw_upsizer into the real build tree, and back out again.
#
#   ./apply_to_tree.sh --status
#   ./apply_to_tree.sh --apply
#   ./apply_to_tree.sh --revert
#
# WHY THIS IS A ONE-FILE SWAP AND NOT A BENDER CHANGE
# ---------------------------------------------------
# target/xilinx/scripts/add_sources.zcu102.tcl already lists
#   .bender/git/checkouts/axi-*/src/axi_dw_upsizer.sv   (line 154)
#   .bender/git/checkouts/common_cells-*/src/id_queue.sv (line 90)
# id_queue is pulled in by common_cells regardless -- axi_dw_downsizer uses it --
# so the patch needs NO new source and NO manifest change. Overwriting the one
# file is sufficient, and nothing in Bender.lock or Bender.yml moves.
#
# The build will not undo it: there is no `bender checkout` anywhere in the
# make flow, and add_sources.zcu102.tcl only regenerates when Bender.yml is
# newer, which it is not.
#
# ⚠ .bender/git/checkouts IS A GENERATED DIRECTORY. `bender checkout`,
# `bender update` or `bender clean` will silently restore the stock file. Run
# --status before trusting a build result.

set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${ROOT:-$(cd "$HERE/.." && pwd)}
TARGET="$ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_dw_upsizer.sv"
PATCHED="$HERE/patched/axi_dw_upsizer.sv"
BACKUP="$HERE/patched/axi_dw_upsizer.sv.stock"
SRCLIST="$ROOT/target/xilinx/scripts/add_sources.zcu102.tcl"

for f in "$TARGET" "$PATCHED"; do
  [ -f "$f" ] || { echo "*** missing: $f"; exit 1; }
done

# Sanity: the file we are about to overwrite must be the one the build reads.
if [ -f "$SRCLIST" ] && ! grep -q 'axi-ecdc900686449c15/src/axi_dw_upsizer.sv' "$SRCLIST"; then
  echo "*** $SRCLIST does not reference that upsizer -- refusing to touch anything"
  exit 1
fi

md5 () { md5sum "$1" 2>/dev/null | cut -d' ' -f1; }

status () {
  local t p b
  t=$(md5 "$TARGET"); p=$(md5 "$PATCHED"); b=$(md5 "$BACKUP")
  echo "  in tree : $t  $TARGET"
  echo "  patched : $p"
  [ -f "$BACKUP" ] && echo "  stock   : $b  (backup)"
  echo
  if [ "$t" = "$p" ]; then
    echo "  STATE: PATCHED is in the build tree."
  elif [ -n "$b" ] && [ "$t" = "$b" ]; then
    echo "  STATE: STOCK is in the build tree."
  elif [ -f "$BACKUP" ]; then
    echo "  STATE: UNKNOWN -- the tree file matches neither. Do not build."
  else
    echo "  STATE: STOCK (no patch has been applied yet)."
  fi
}

case "${1:---status}" in
  --status)
    status
    ;;
  --apply)
    if [ ! -f "$BACKUP" ]; then
      cp -p "$TARGET" "$BACKUP"
      echo "  saved stock copy -> $BACKUP"
    fi
    if [ "$(md5 "$TARGET")" = "$(md5 "$PATCHED")" ]; then
      echo "  already applied, nothing to do"
    else
      cp -p "$PATCHED" "$TARGET"
      echo "  applied patched upsizer into the build tree"
    fi
    echo
    status
    echo
    echo "  Now build a 2-LANE config -- that is the only one with the converter."
    echo "  At 4 lanes the widths match and axi_dw_converter collapses to wires,"
    echo "  so a 4-lane build would measure nothing."
    ;;
  --revert)
    if [ ! -f "$BACKUP" ]; then
      echo "*** no backup at $BACKUP -- cannot revert."
      echo "*** restore with: bender checkout   (regenerates the checkout)"
      exit 1
    fi
    cp -p "$BACKUP" "$TARGET"
    echo "  restored stock upsizer"
    echo
    status
    ;;
  *)
    echo "usage: $0 [--status|--apply|--revert]"
    exit 1
    ;;
esac
