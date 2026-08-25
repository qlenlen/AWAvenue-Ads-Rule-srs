#!/usr/bin/env bash
# Sync sing-box rule sources from TG-Twilight/AWAvenue-Ads-Rule and compile them to .srs.
# Requires: bash, curl, jq, tar. Runs on GitHub Actions ubuntu runners.
set -euo pipefail

UPSTREAM_REPO="TG-Twilight/AWAvenue-Ads-Rule"
UPSTREAM_BRANCH="main"
SRS_DIR="srs"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# GitHub API helper: uses GH_TOKEN when available (Actions) to raise rate limits.
api() {
  if [[ -n "${GH_TOKEN:-}" ]]; then
    curl -fsSL -H "Authorization: Bearer ${GH_TOKEN}" "$1"
  else
    curl -fsSL "$1"
  fi
}

# Raw content helper (uncached by commit SHA).
raw() {
  curl -fsSL "https://raw.githubusercontent.com/${UPSTREAM_REPO}/${UPSTREAM_SHA}/$1"
}

# ---------------------------------------------------------------------------
# 1. Always resolve the latest sing-box pre-release.
# ---------------------------------------------------------------------------
SB_TAG="$(api "https://api.github.com/repos/SagerNet/sing-box/releases?per_page=30" \
  | jq -r '[.[] | select(.draft == false and .prerelease == true)][0].tag_name')"
if [[ -z "$SB_TAG" || "$SB_TAG" == "null" ]]; then
  echo "ERROR: no sing-box pre-release found" >&2
  exit 1
fi
echo "Using sing-box ${SB_TAG}"

case "$(uname -m)" in
  x86_64)          SB_ARCH="amd64" ;;
  aarch64 | arm64) SB_ARCH="arm64" ;;
  *) echo "ERROR: unsupported arch $(uname -m)" >&2; exit 1 ;;
esac
SB_VER="${SB_TAG#v}"
curl -fsSL \
  "https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-${SB_ARCH}.tar.gz" \
  | tar -xz -C "$WORK_DIR"
SING_BOX="$WORK_DIR/sing-box-${SB_VER}-linux-${SB_ARCH}/sing-box"
chmod +x "$SING_BOX"
"$SING_BOX" version

# ---------------------------------------------------------------------------
# 2. Pin the upstream commit we sync from (also used for traceability).
# ---------------------------------------------------------------------------
UPSTREAM_SHA="$(api "https://api.github.com/repos/${UPSTREAM_REPO}/commits/${UPSTREAM_BRANCH}" | jq -r '.sha')"
echo "Upstream ${UPSTREAM_REPO}@${UPSTREAM_SHA}"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "UPSTREAM_SHA=${UPSTREAM_SHA}" >> "$GITHUB_ENV"
fi

# ---------------------------------------------------------------------------
# 3. Discover sing-box rule-source JSON files in the upstream tree.
# ---------------------------------------------------------------------------
api "https://api.github.com/repos/${UPSTREAM_REPO}/git/trees/${UPSTREAM_SHA}?recursive=1" \
  | jq -r '.tree[] | select(.type == "blob") | .path' > "$WORK_DIR/paths.txt"

JSON_PATHS="$(grep -Ei 'sing.?box[^/]*\.json$|/sing-box/.*\.json$' "$WORK_DIR/paths.txt" || true)"
if [[ -z "$JSON_PATHS" ]]; then
  # Fallback: any JSON under Filters/.
  JSON_PATHS="$(grep -E '^Filters/.*\.json$' "$WORK_DIR/paths.txt" || true)"
fi
if [[ -z "$JSON_PATHS" ]]; then
  echo "ERROR: no sing-box rule JSON found upstream" >&2
  exit 1
fi
echo "Found rule sources:"; echo "$JSON_PATHS"

# ---------------------------------------------------------------------------
# 4. Download and compile each rule source to .srs.
# ---------------------------------------------------------------------------
mkdir -p "$SRS_DIR"
FAILED=0
while IFS= read -r path; do
  name="$(basename "$path" .json)"
  out="${SRS_DIR}/${name}.srs"
  echo "::group::compile ${path} -> ${out}"
  src="${WORK_DIR}/$(basename "$path")"
  if ! raw "$path" > "$src"; then
    echo "ERROR: failed to download ${path}" >&2
    FAILED=1
    continue
  fi
  if ! "$SING_BOX" rule-set compile "$src" -o "$out"; then
    echo "ERROR: failed to compile ${path}" >&2
    FAILED=1
    continue
  fi
  if [[ ! -s "$out" ]]; then
    echo "ERROR: empty output for ${path}" >&2
    FAILED=1
    continue
  fi
  echo "::endgroup::"
done <<< "$JSON_PATHS"

if (( FAILED != 0 )); then
  echo "ERROR: one or more rules failed to compile" >&2
  exit 1
fi

ls -l "$SRS_DIR"
