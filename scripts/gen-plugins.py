#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""批量生成 100 个深度插件(plugins/*.yml)。
仅使用面板插件引擎提供的函数: arg/ret/kv_set/kv_get/fetch/substr/len/itoa/atoi/log,
以及 if/while/算术/字符串拼接。每个插件按 name/version/desc/url + tools(+tasks) 规范生成。
用法: python3 scripts/gen-plugins.py   (在仓库根目录运行)
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "plugins")

def w(name, desc, esc, tools, tasks=None):
    parts = ["# -*- " + name + " 插件 -- 深度功能示例.",
             "name: " + name,
             "version: 1.0.0",
             "desc: " + desc,
             "url: plugins/" + name + ".yml",
             "", "tools:"]
    for t in tools:
        tid, tdesc, params, script = t
        parts.append("  - id: " + tid)
        parts.append("    desc: " + tdesc)
        if params:
            parts.append("    params:")
            for p in params:
                parts.append("      - id: " + p[0])
                parts.append("        name: " + p[1])
                parts.append("        type: " + p[2])
                parts.append("        required: " + str(p[3]).lower())
                parts.append("        desc: " + p[4])
        parts.append("    script: |")
        for line in script.split("\n"):
            parts.append("      " + line)
    if tasks:
        parts.append("tasks:")
        for t in tasks:
            tid, every, tdesc, script = t
            parts.append("  - id: " + tid)
            parts.append("    every: " + str(every))
            parts.append("    desc: " + tdesc)
            parts.append("    script: |")
            for line in script.split("\n"):
                parts.append("      " + line)
    with open(os.path.join(os.path.dirname(OUT), name + ".yml") if False else os.path.join(OUT, name + ".yml"), "w") as f:
        f.write("\n".join(parts) + "\n")

os.makedirs(OUT, exist_ok=True)

# 公共脚本片段
SUM_SCRIPT = """n = itoa(0)
i = 0"""

def main():
    gen()

def gen():
    pass