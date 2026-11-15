#!/usr/bin/env bash
# 從 xcode/src/ 組裝出 M01–M${MAX} 的 starter / solution 資料夾（MAX 預設 10，可用環境變數覆寫：
#   MAX=8 scripts/assemble.sh）。資料夾名稱一律兩位數：M01 … M09、M10。
#
#   src/common/                 所有里程碑共用：project.yml、AppDelegate、SceneDelegate、main.m
#   src/MNN/solution/LittleBook 該里程碑完成後的程式碼（會覆蓋前面里程碑的同名檔，例如 M05 的 LBLedger）
#   src/MNN/starter/LittleBook  只放「和 solution 不同」的檔案（空殼 / 埋雷版），組裝時覆蓋到 solution 上
#   src/MNN/tests/LittleBookTests  該里程碑的測試（starter 與 solution 都放）
#
# starter(N)  = common + solution(1..N) 再疊上 starter(N) + tests(1..N)
# solution(N) = common + solution(1..N) + tests(1..N)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/src"
MAX="${MAX:-10}"

milestone() {   # milestone <N> → M01 … M10
    printf 'M%02d' "$1"
}

copy_tree() {   # copy_tree <來源資料夾> <目的資料夾>
    if [ -d "$1" ]; then
        mkdir -p "$2"
        cp -R "$1"/. "$2"/
    fi
}

assemble() {    # assemble <N> <starter|solution>
    local n="$1" kind="$2"
    local dest
    dest="$ROOT/$(milestone "$n")-${kind}"
    rm -rf "$dest"
    mkdir -p "$dest"
    cp "$SRC/common/project.yml" "$dest/project.yml"
    copy_tree "$SRC/common/LittleBook" "$dest/LittleBook"
    for k in $(seq 1 "$n"); do
        local m
        m="$(milestone "$k")"
        copy_tree "$SRC/$m/solution/LittleBook" "$dest/LittleBook"
        copy_tree "$SRC/$m/tests/LittleBookTests" "$dest/LittleBookTests"
    done
    if [ "$kind" = "starter" ]; then
        copy_tree "$SRC/$(milestone "$n")/starter/LittleBook" "$dest/LittleBook"
    fi
    echo "assembled $dest"
}

for n in $(seq 1 "$MAX"); do
    assemble "$n" starter
    assemble "$n" solution
done
