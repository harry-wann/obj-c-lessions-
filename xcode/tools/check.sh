#!/usr/bin/env bash
# 用替身 SDK 對每個 .m 做 clang -fsyntax-only
# 用法：bash xcode/tools/check.sh xcode/M10-solution（需要 clang；替身 SDK 只抓語法與型別錯，不代表能在真 Xcode 建置）
#       WITH_PODS=1 bash xcode/tools/check.sh xcode/M11-solution
#         → 多加 stub-pods/（Masonry 替身），檢查 #if __has_include(<Masonry/Masonry.h>) 那一支
# 只檢查 .m；.swift、.storyboard、.xib 不在範圍內（Storyboard / XIB 用 xmllint --noout）。
SDK="$(cd "$(dirname "$0")" && pwd)/stub-sdk"
PODS="$(cd "$(dirname "$0")" && pwd)/stub-pods"
extra=()
if [ "${WITH_PODS:-0}" = "1" ]; then extra=(-isystem "$PODS"); fi
MC="${TMPDIR:-/tmp}/lb-stub-modcache"
dir="$1"
incs=()
while IFS= read -r d; do incs+=(-I "$d"); done < <(find "$dir/LittleBook" "$dir/LittleBookTests" -type d 2>/dev/null)
fail=0
while IFS= read -r f; do
  out=$(clang -target x86_64-apple-ios17.0-simulator -fsyntax-only -fobjc-arc -fblocks -fmodules \
    -fmodules-cache-path="$MC" -nostdlibinc -isystem "$SDK" "${extra[@]}" "${incs[@]}" \
    -Wall -Wextra -Wno-unused-parameter -Wobjc-designated-initializers -Wnullability-completeness \
    -Wno-missing-field-initializers -Wno-sign-compare -Wundeclared-selector -Wshadow-ivar \
    -Wimplicit-retain-self -Wno-gnu-zero-variadic-macro-arguments -Wno-format-extra-args \
    -Wno-unused-value "$f" 2>&1)
  if [ -n "$out" ]; then echo "=== $f"; echo "$out"; fail=1; fi
done < <(find "$dir/LittleBook" "$dir/LittleBookTests" -name '*.m' | sort)
exit $fail
