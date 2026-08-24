#!/usr/bin/env bash
# 把 docker-images.list 里的常用镜像 pull 下来，每个镜像打成 zip 放入 docker/ 目录，
# 供 plugins.yml 以 `zip: docker/<别名>.zip` + `kind: docker` 方式引用（相对路径自动套加速）。
# zip 内含：image.tar.gz（docker save 的镜像）、install.sh（离线导入脚本）、
#          docker-compose.yml（对已知服务生成默认编排骨架）。
# 产物（docker/*.zip）请提交回仓库，端上即可通过加速链整个下载解压。
set -euo pipefail

LIST="docker-images.list"
OUT_DIR="docker"
mkdir -p "$OUT_DIR"

# 根据别名返回默认端口，用于 compose 骨架；无则返回空（仅离线导入）
port_for() {
  case "$1" in
    mysql) echo 3306 ;;
    redis) echo 6379 ;;
    postgres) echo 5432 ;;
    mariadb) echo 3306 ;;
    mongo) echo 27017 ;;
    nginx|openresty) echo 80 ;;
    php) echo 9000 ;;
    traefik) echo 8080 ;;
    rabbitmq) echo 5672 ;;
    elasticsearch) echo 9200 ;;
    grafana) echo 3000 ;;
    prometheus) echo 9090 ;;
    portainer) echo 9443 ;;
    *) echo "" ;;
  esac
}

while read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue

  image="${line%% *}"
  alias="$(echo "$line" | awk '{print $2}')"
  port="$(port_for "$alias")"

  echo "== pull $image"
  docker pull "$image"

  tmp="$(mktemp -d)"
  mkdir -p "$tmp/$alias"

  echo "-- 导出镜像"
  docker save "$image" | gzip -9 > "$tmp/$alias/image.tar.gz"

  cat > "$tmp/$alias/install.sh" <<EOF
#!/usr/bin/env bash
# 离线导入 ${alias}（来自 ${image}）
set -e
docker load -i "\$(dirname "\$0")/image.tar.gz"
echo "已导入镜像: ${image}"
EOF
  chmod +x "$tmp/$alias/install.sh"

  if [[ -n "$port" ]]; then
    cat > "$tmp/$alias/docker-compose.yml" <<EOF
# ${alias} 离线部署骨架（镜像来自仓库，无需在线拉取）
services:
  ${alias}:
    image: ${image}
    restart: unless-stopped
    ports:
      - "${port}:${port}"
EOF
  fi

  echo "-- 打包 docker/${alias}.zip"
  ( cd "$tmp" && zip -qr "$OLDPWD/$OUT_DIR/$alias.zip" . )
  rm -rf "$tmp"
done < "$LIST"

echo "完成。整包在 $OUT_DIR/*.zip，请提交回仓库；并在 plugins.yml 追加："
echo "  - id: <id>"
echo "    name: <显示名>"
echo "    desc: <描述>"
echo "    zip: $OUT_DIR/<别名>.zip"
echo "    kind: docker  # docker 部署包，相对路径走加速"