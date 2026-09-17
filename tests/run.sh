#!/usr/bin/env sh
# Render từng fixture qua harness chart rồi so với golden.
# UPDATE_GOLDEN=1 để ghi lại golden sau khi đổi template có chủ ý.
# Golden test yêu cầu helm v4 (v4 append newline vào output rỗng).
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS="$ROOT/tests/harness"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Đóng gói lại library mỗi lần chạy, nếu không harness dùng bản .tgz cũ.
rm -rf "$HARNESS/charts" "$HARNESS/Chart.lock"
helm dependency update "$HARNESS" >/dev/null

status=0
for fixture in "$ROOT"/tests/fixtures/*/; do
    name=$(basename "$fixture")
    golden="$ROOT/tests/golden/$name.yaml"
    actual="$TMP/$name.yaml"

    helm template test "$HARNESS" --values "$fixture/values.yaml" > "$actual"

    if [ "${UPDATE_GOLDEN:-}" = "1" ]; then
        cp "$actual" "$golden"
        echo "updated  $name"
        continue
    fi

    if diff -u "$golden" "$actual"; then
        echo "ok       $name"
    else
        echo "FAIL     $name"
        status=1
    fi
done

_libkeys="$TMP/libkeys.json"
_hkeys="$TMP/harnesskeys.json"
yq -o=json 'sort_keys(del(.workloads))' "$ROOT/values.yaml" >"$_libkeys"
yq -o=json 'sort_keys(del(.workloads))' "$ROOT/tests/harness/values.yaml" >"$_hkeys"
if diff -q "$_libkeys" "$_hkeys" >/dev/null; then
    echo "ok       harness-values-sync"
else
    echo "FAIL     harness-values-sync (tests/harness/values.yaml lệch default trong values.yaml)"
    diff -u "$_libkeys" "$_hkeys" || true
    status=1
fi

exit "$status"
