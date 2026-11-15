#!/usr/bin/env bash
# 從 xcode/src/ 組裝出 M01–M05 的 starter / solution 資料夾。
#
#   src/common/                 所有里程碑共用：project.yml、AppDelegate、SceneDelegate、main.m
#   src/M0X/solution/LittleBook 該里程碑完成後的程式碼（會覆蓋前面里程碑的同名檔，例如 M05 的 LBLedger）
#   src/M0X/starter/LittleBook  只放「和 solution 不同」的檔案（空殼 / 埋雷版），組裝時覆蓋到 solution 上
#   src/M0X/tests/LittleBookTests  該里程碑的測試（starter 與 solution 都放）
#
# starter(N)  = common + solution(1..N) 再疊上 starter(N) + tests(1..N)
# solution(N) = common + solution(1..N) + tests(1..N)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/src"

copy_tree() {   # copy_tree <來源資料夾> <目的資料夾>
    if [ -d "$1" ]; then
        mkdir -p "$2"
        cp -R "$1"/. "$2"/
    fi
}

assemble() {    # assemble <N> <starter|solution>
    local n="$1" kind="$2"
    local dest="$ROOT/M0${n}-${kind}"
    rm -rf "$dest"
    mkdir -p "$dest"
    cp "$SRC/common/project.yml" "$dest/project.yml"
    copy_tree "$SRC/common/LittleBook" "$dest/LittleBook"
    for k in $(seq 1 "$n"); do
        copy_tree "$SRC/M0${k}/solution/LittleBook" "$dest/LittleBook"
        copy_tree "$SRC/M0${k}/tests/LittleBookTests" "$dest/LittleBookTests"
    done
    if [ "$kind" = "starter" ]; then
        copy_tree "$SRC/M0${n}/starter/LittleBook" "$dest/LittleBook"
    fi
    echo "assembled $dest"
}

for n in 1 2 3 4 5; do
    assemble "$n" starter
    assemble "$n" solution
done
