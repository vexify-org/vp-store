#!/usr/bin/env bash
# 把 docker-images.list 里的常用镜像 pull 下来，docker save 压缩成 dist/<别名>.tar.gz，
# 并生成 manifest.txt 供核对。产物上传到 GitHub Releases（建议放到 assets/images/ 目录），
# apps.yml 里的离线安装条目会通过 {accel} 加速前缀下载这些包。
set -euo pipefail

LIST="docker-images.list"
OUT_DIR="dist"
mkdir -p "$OUT_DIR"

: > "$OUT_DIR/manifest.txt"

while read -r line; do
  # 跳过空行与注释
  [[ -z "$line" || "$line" == \#* ]] && continue

  image="${line%% *}"
  alias="$(echo "$line" | awk '{print $2}')"

  echo "== pull $image"
  docker pull "$image"

  outfile="$OUT_DIR/${alias}.tar.gz"
  echo "== save -> $outfile"
  docker save "$image" | gzip -9 > "$outfile"
  printf '%-16s <- %s (%s)\n' "$alias" "$image" "$(du -h "$outfile" | cut -f1)" >> "$OUT_DIR/manifest.txt"
done < "$LIST"

echo "完成。产物在 $OUT_DIR/，清单见 $OUT_DIR/manifest.txt"
echo "之后把 $OUT_DIR/*.tar.gz 上传到 GitHub Release（目录 assets/images/），apps 端即可离线安装。"