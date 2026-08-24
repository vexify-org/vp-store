# vp-store

vPanel 的一键商店清单仓库。面板运行时通过加速前缀实时拉取本仓库的 `apps.yml`（软件商店）与 `plugins.yml`（插件商店），改清单即改商店，无需改面板代码。

## 软件商店 apps.yml

顶层 `apps` 数组，每个条目一个软件：

```yaml
- id: nginx          # 唯一标识
  name: Nginx        # 显示名
  desc: 描述
  script: |          # 安装脚本；{accel} 会被替换为当前加速前缀
    set -e
    apt-get install -y nginx
```

## 插件商店 plugins.yml

顶层 `plugins` 数组，每个条目一个插件，支持两种取件方式：

```yaml
- id: demo           # 唯一标识
  name: demo         # 显示名
  desc: 描述
  file: plugins/demo.yml   # 方式一：仓库内单个插件 yml（相对路径）
  # ---- 方式二（推荐，任选）：整包 zip 直链 ----
  # zip: docker/trojan.zip  # 仓库内 zip 相对路径，自动套加速；也可填 http(s) 绝对直链
  # kind: plugin            # plugin=插件(默认) / docker=docker 部署包
```

- `file`：传统方式，面板下载仓库内单个插件 yml。
- `zip` + `kind`（配套使用）：面板**一律下载整个 zip** 而非逐个拉单文件；相对路径自动套上加速前缀，下载更快。`kind` 决定解压位置：
  - `plugin`（默认）：解压进 vPanel 的插件目录，随后扫描并加载其中的 `*.yml`。
  - `docker`：解压进 vPanel 的 docker 目录（默认 `/docker`，可在面板配置 `download.docker_dir` 调整）。

示例：

```yaml
plugins:
  - id: demo
    name: demo
    desc: 官方示例插件
    file: plugins/demo.yml

  - id: trojan
    name: Trojan
    desc: 自建代理
    zip: docker/trojan.zip
    kind: docker

  - id: my-cool-plugin
    name: My Cool Plugin
    desc: 我的插件
    zip: plugins/my-cool-plugin.zip
    kind: plugin
```

## 如何新增

1. 软件商店：在 `apps.yml` 末尾追加一条 `App`。
2. 插件商店（单文件）：在 `plugins.yml` 追加一条，`file` 指向 `plugins/<name>.yml`。
3. 插件商店（整包）：把打包好的 zip 放进仓库，在 `plugins.yml` 追加 `zip` + `kind`。

提交合并后，面板商店会自动刷新（带 60s 缓存）。