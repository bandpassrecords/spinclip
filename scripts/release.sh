#!/bin/bash
# Bump pubspec.yaml's version, verify CHANGELOG.md has a matching entry, and
# create an annotated vX.Y.Z tag locally.
# Usage: ./scripts/release.sh <version> [--push] [--remote <name>]
# Example: ./scripts/release.sh 0.2.0 --push
#
# Nothing is pushed unless --push is given, since pushing a tag/commit is a
# shared, hard-to-reverse action best left to an explicit choice. Pushing the
# tag is what triggers .github/workflows/release.yml's build-and-upload job -
# create a matching GitHub Release for the tag first (the workflow attaches
# build artifacts to an existing release; it does not create one).

set -e

VERSION="$1"
shift || true

PUSH=false
REMOTE="origin"

while [ $# -gt 0 ]; do
  case "$1" in
    --push) PUSH=true ;;
    --remote) REMOTE="$2"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version> [--push] [--remote <name>]" >&2
  echo "Example: $0 0.2.0" >&2
  exit 1
fi

if ! echo "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Error: version must be X.Y.Z (got: $VERSION)" >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
PUBSPEC="$REPO_ROOT/pubspec.yaml"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
TAG="v$VERSION"

if [ ! -f "$PUBSPEC" ]; then
  echo "Error: $PUBSPEC not found" >&2
  exit 1
fi

if git -C "$REPO_ROOT" rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: tag $TAG already exists locally" >&2
  exit 1
fi

if ! grep -qE "^## v$VERSION( |$)" "$CHANGELOG"; then
  echo "Error: $CHANGELOG has no '## v$VERSION' entry yet. Add one (with a date and highlights) before releasing." >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" diff --quiet -- "$PUBSPEC" || ! git -C "$REPO_ROOT" diff --cached --quiet -- "$PUBSPEC"; then
  echo "Error: $PUBSPEC has uncommitted changes -- commit or stash them first" >&2
  exit 1
fi

CURRENT_BUILD=$(grep -oE '^version: [0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)' "$PUBSPEC" | grep -oE '[0-9]+$')
NEXT_BUILD=$(( ${CURRENT_BUILD:-0} + 1 ))

sed -i.bak -E "s/^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: $VERSION+$NEXT_BUILD/" "$PUBSPEC"
rm -f "$PUBSPEC.bak"

echo "Bumped $PUBSPEC to $VERSION+$NEXT_BUILD"

git -C "$REPO_ROOT" add "$PUBSPEC"
git -C "$REPO_ROOT" commit -m "Bump version to $TAG"
git -C "$REPO_ROOT" tag -a "$TAG" -m "$TAG"

echo "Committed and tagged $TAG locally."

if [ "$PUSH" = true ]; then
  echo "Pushing commit and tag to $REMOTE..."
  git -C "$REPO_ROOT" push "$REMOTE" HEAD
  git -C "$REPO_ROOT" push "$REMOTE" "$TAG"
  echo "Pushed. Create a GitHub Release for $TAG (if you haven't already) so the release workflow has somewhere to attach build artifacts."
else
  echo "Not pushed. To publish: git push $REMOTE HEAD && git push $REMOTE $TAG"
fi
