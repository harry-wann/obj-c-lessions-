#!/usr/bin/env bash
# 從 xcode/src/ 組裝出 M01–M${MAX} 的 starter / solution 資料夾（MAX 預設 12，可用環境變數覆寫：
#   MAX=8 scripts/assemble.sh）。資料夾名稱一律兩位數：M01 … M09、M10 … M12。
#
#   src/common/                    所有里程碑共用：project.yml、AppDelegate、SceneDelegate、main.m
#   src/MNN/solution/LittleBook    該里程碑完成後的程式碼（會覆蓋前面里程碑的同名檔，例如 M05 的 LBLedger）
#   src/MNN/solution/root          放在專案根目錄的檔案（M11 起：project.yml、Podfile、.clang-format），
#                                  一樣會累積、覆蓋 common 的同名檔
#   src/MNN/starter/LittleBook     只放「和 solution 不同」的檔案（空殼 / 埋雷版），組裝時覆蓋到 solution 上
#   src/MNN/starter/LittleBookTests  starter 專用的測試資源（例如 M11 全部 NO 的 LegacyAudit.plist）
#   src/MNN/starter/root           starter 專用的根目錄檔案
#   src/MNN/starter/remove.txt     starter(N) 要刪掉的檔案（相對專案根目錄，一行一個，# 開頭是註解）：
#                                  例如 M11 的 Settings.storyboard 要學生自己建，starter 不能先有
#   src/MNN/tests/LittleBookTests  該里程碑的測試（starter 與 solution 都放）
#
# starter(N)  = common + solution(1..N) 再疊上 starter(N) + tests(1..N)，最後刪掉 remove.txt 列的檔
# solution(N) = common + solution(1..N) + tests(1..N)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/src"
MAX="${MAX:-12}"

milestone() {   # milestone <N> → M01 … M12
    printf 'M%02d' "$1"
}

copy_tree() {   # copy_tree <來源資料夾> <目的資料夾>（含隱藏檔，例如 .clang-format）
    if [ -d "$1" ]; then
        mkdir -p "$2"
        cp -R "$1"/. "$2"/
    fi
}

remove_listed() {   # remove_listed <清單檔> <專案根目錄>
    local list="$1" dest="$2" line
    [ -f "$list" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"                       # 去掉註解
        line="$(echo "$line" | xargs)"           # 去掉前後空白
        [ -n "$line" ] || continue
        case "$line" in
            /* | *..*) echo "remove.txt 不接受絕對路徑或 ..：$line" >&2; exit 1 ;;
        esac
        if [ ! -e "$dest/$line" ]; then
            echo "remove.txt 列的檔案不存在（來源改名了？）：$line" >&2
            exit 1
        fi
        rm -rf "${dest:?}/$line"
    done < "$list"
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
        copy_tree "$SRC/$m/solution/root" "$dest"
        copy_tree "$SRC/$m/solution/LittleBook" "$dest/LittleBook"
        copy_tree "$SRC/$m/tests/LittleBookTests" "$dest/LittleBookTests"
    done
    if [ "$kind" = "starter" ]; then
        local cur
        cur="$SRC/$(milestone "$n")/starter"
        copy_tree "$cur/root" "$dest"
        copy_tree "$cur/LittleBook" "$dest/LittleBook"
        copy_tree "$cur/LittleBookTests" "$dest/LittleBookTests"
        remove_listed "$cur/remove.txt" "$dest"
    fi
    echo "assembled $dest"
}

for n in $(seq 1 "$MAX"); do
    assemble "$n" starter
    assemble "$n" solution
done
