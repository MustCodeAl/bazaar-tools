#!/usr/bin/env bash
# Bazaar shell version of bazaar-tools (set-root)
# Usage:
#   ./bazaar set-root [--keep-components] [--select <homepage>]
set -euo pipefail

# Require bash >= 4 for associative arrays and globstar
if [ -z "${BASH_VERSINFO:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "This script requires bash >= 4" >&2
  exit 1
fi

shopt -s globstar dotglob nullglob

# HOMEPAGES mapping: keys are homepage names (user chooses these), values are the exact layout folder names under src/app
declare -A HOMEPAGES=(
  [fashion-1]="fashion-1"
  [fashion-2]="fashion-2"
  [fashion-3]="fashion-3"
  [furniture-1]="furniture-1"
  [furniture-2]="furniture-2"
  [furniture-3]="furniture-3"
  [gift-shop]="gift-shop"
  [gadget-1]="gadget-1"
  [gadget-2]="gadget-2"
  [gadget-3]="gadget-3"
  [grocery-1]="grocery-1"
  [grocery-2]="grocery-2"
  [grocery-3]="grocery-3"
  [grocery-4]="grocery-4"
  [health-beauty]="health-beauty"
  [market-1]="market-1"
  [market-2]="market-2"
  [medical]="medical"

  # Added exact shop-style layout names per your earlier request
  [furniture-shop]="furniture-shop"
  [health-beauty-shop]="health-beauty-shop"
  [gadget-shop]="gadget-shop"
)

ROOT_DIR="$(pwd)"
SCRIPT_NAME="$(basename "$0")"

print_usage() {
  cat <<EOF
Usage: $SCRIPT_NAME set-root [--keep-components] [--select <homepage>] [-h|--help]

Commands:
  set-root           Interactive or scripted setup to set a homepage as the app root.
Options:
  --keep-components  Do not delete src/pages-sections for unselected homepages.
  --select <name>    Select the homepage non-interactively (must be one of HOMEPAGES keys or "landing").
  -h, --help         Show this help.
EOF
}

# detect file extension by searching for any layout.tsx in src/app (including parenthesized containers)
get_file_ext() {
  for f in "$ROOT_DIR"/src/app/**/layout.tsx "$ROOT_DIR"/src/app/layout.tsx; do
    if [ -f "$f" ]; then
      echo "tsx"
      return 0
    fi
  done
  echo "jsx"
}

# merge directories recursively by moving contents into dest. Use rsync if available for robustness.
merge_directories() {
  local src="$1"
  local dest="$2"

  [ -d "$src" ] || return 0
  mkdir -p "$dest"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --remove-source-files --exclude='*/' "$src"/ "$dest"/ || true
    for d in "$src"/*/; do
      [ -d "$d" ] || continue
      local name
      name="$(basename "$d")"
      merge_directories "$src/$name" "$dest/$name"
    done
    rm -rf "$src"
  else
    for entry in "$src"/*; do
      [ -e "$entry" ] || continue
      mv -f "$entry" "$dest/"
    done
    rm -rf "$src"
  fi
}

# Return list (newline-separated) of parenthesized container directories under src/app (e.g., (layout-1), (layout-2))
list_parenthesized_containers() {
  local app_root="$ROOT_DIR/src/app"
  [ -d "$app_root" ] || return 0
  for d in "$app_root"/\(*\)/; do
    [ -d "$d" ] || continue
    printf "%s\n" "${d%/}"  # trim trailing slash
  done
}

# Given a layout name, return candidate exact paths where that layout folder might be:
#  - src/app/<layout>
#  - src/app/(layout-x)/<layout> for any parenthesized container
find_exact_layout_paths() {
  local layout="$1"
  local app_root="$ROOT_DIR/src/app"

  # direct exact path
  local p="$app_root/$layout"
  if [ -d "$p" ]; then
    printf "%s\n" "$p"
  fi

  # check inside parenthesized containers, e.g. src/app/(layout-1)/<layout>
  while read -r container; do
    [ -z "$container" ] && continue
    local cand="$container/$layout"
    if [ -d "$cand" ]; then
      printf "%s\n" "$cand"
    fi
  done < <(list_parenthesized_containers)
}

prompt_select_homepage() {
  local choices=()
  for key in "${!HOMEPAGES[@]}"; do
    choices+=("$key")
  done
  choices+=("landing")

  echo "Select a homepage to set as root:"
  local i=1
  for c in "${choices[@]}"; do
    printf "  %2d) %s\n" "$i" "$c"
    i=$((i + 1))
  done

  local pick
  while true; do
    read -r -p "Enter number: " pick
    if [[ "$pick" =~ ^[0-9]+$ ]] && [ "$pick" -ge 1 ] && [ "$pick" -le "${#choices[@]}" ]; then
      echo "${choices[$((pick-1))]}"
      return 0
    fi
    echo "Invalid choice. Try again."
  done
}

run_set_root() {
  local keep_components=false
  local selected_override=""
  # parse args
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --keep-components) keep_components=true; shift ;;
      --select) selected_override="${2:-}"; shift 2 ;;
      -h|--help) print_usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; print_usage; exit 2 ;;
    esac
  done

  local file_ext
  file_ext="$(get_file_ext)"

  local selected
  if [ -n "$selected_override" ]; then
    selected="$selected_override"
    if [ "$selected" != "landing" ] && [ -z "${HOMEPAGES[$selected]:-}" ]; then
      echo "Invalid --select value: $selected" >&2
      echo "Valid values: landing or one of:" >&2
      for k in "${!HOMEPAGES[@]}"; do echo "  - $k"; done
      exit 3
    fi
  else
    selected="$(prompt_select_homepage)"
  fi

  echo "Selected homepage: $selected"
  echo "Keep components: $keep_components"
  echo "Detected file extension for pages: $file_ext"

  # Remove unused page sections unless keep-components true
  if [ "$keep_components" = false ]; then
    for page in "${!HOMEPAGES[@]}"; do
      if [ "$page" != "$selected" ]; then
        local page_section="$ROOT_DIR/src/pages-sections/$page"
        if [ -e "$page_section" ]; then
          echo "Removing page sections: $page_section"
          rm -rf "$page_section"
        fi
      fi
    done
    if [ "$selected" != "landing" ]; then
      if [ -e "$ROOT_DIR/src/pages-sections/landing" ]; then
        echo "Removing page sections: src/pages-sections/landing"
        rm -rf "$ROOT_DIR/src/pages-sections/landing"
      fi
    fi
  else
    echo "Keeping page-sections components"
  fi

  # Remove unused homepage layouts and prepare selected one
  for page in "${!HOMEPAGES[@]}"; do
    layout="${HOMEPAGES[$page]}"

    if [ "$page" != "$selected" ]; then
      # Remove exact-match layout paths (direct and inside parenthesized containers)
      mapfile -t candidates < <(find_exact_layout_paths "$layout")
      for c in "${candidates[@]}"; do
        if [ -n "$c" ] && [ "$c" != "$ROOT_DIR/src/app" ]; then
          echo "Removing unused layout path: $c"
          rm -rf "$c"
        fi
      done
    else
      # Selected: look for exact path(s)
      mapfile -t candidates < <(find_exact_layout_paths "$layout")

      if [ "${#candidates[@]}" -eq 0 ]; then
        echo "Warning: selected layout '$layout' not found in src/app or parenthesized containers."
        continue
      fi

      # Prefer direct src/app/<layout> if present, otherwise handle parenthesized container candidate(s)
      local handled=false
      for cand in "${candidates[@]}"; do
        # if candidate parent is a parenthesized container, follow the Node behavior:
        # move <container>/<layout>/page.<ext> -> <container>/page.<ext> and remove <container>/<layout>
        parent="$(dirname "$cand")"
        base_parent="$(basename "$parent")"
        if [[ "$base_parent" =~ ^\(.+\)$ ]]; then
          src_page_candidate="$cand/page.$file_ext"
          dest_page="$parent/page.$file_ext"
          if [ -f "$src_page_candidate" ]; then
            echo "Selected layout is nested under parenthesized container."
            echo "Moving $src_page_candidate -> $dest_page"
            mkdir -p "$(dirname "$dest_page")"
            mv -f "$src_page_candidate" "$dest_page"
            # remove the now-empty nested layout folder
            rm -rf "$cand"
          else
            # maybe page file is nested deeper (e.g., cand/<page>/page.ext)
            if [ -d "$cand/$page" ] && [ -f "$cand/$page/page.$file_ext" ]; then
              echo "Moving $cand/$page/page.$file_ext -> $dest_page"
              mv -f "$cand/$page/page.$file_ext" "$dest_page"
              rm -rf "$cand/$page"
            else
              echo "Warning: expected page file not found under $cand"
            fi
          fi
          handled=true
          # After moving page, merge remaining files from container (if any)
          # The container may have other layout children; keep them by merging into a parenthesized folder name as in original tool
          # Ensure parent moves to parenthesized name (it already is), so nothing else required
        else
          # direct path e.g., src/app/<layout>
          oldPath="$cand"
          newPath="$ROOT_DIR/src/app/($layout)"
          # if nested page exists under oldPath/<page>/page.ext, move it up
          if [ -f "$oldPath/$page/page.$file_ext" ]; then
            echo "Moving $oldPath/$page/page.$file_ext -> $oldPath/page.$file_ext"
            mv -f "$oldPath/$page/page.$file_ext" "$oldPath/page.$file_ext"
            rm -rf "$oldPath/$page"
          fi
          mkdir -p "$newPath"
          echo "Merging $oldPath -> $newPath"
          merge_directories "$oldPath" "$newPath"
          handled=true
        fi
      done

      if [ "$handled" = false ]; then
        echo "Warning: could not process selected layout '$layout' (no suitable candidate handled)."
      fi
    fi
  done

  # remove existing root page file (same as original)
  root_page="$ROOT_DIR/src/app/page.$file_ext"
  if [ -f "$root_page" ]; then
    echo "Removing existing root page: $root_page"
    rm -f "$root_page"
  fi

  echo ""
  echo "$selected has been set as root page."
  echo "Done."
}

# CLI
if [ "$#" -lt 1 ]; then
  print_usage
  exit 1
fi

cmd="$1"; shift
case "$cmd" in
  set-root)
    run_set_root "$@"
    ;;
  -h|--help)
    print_usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    print_usage
    exit 2
    ;;
esac
