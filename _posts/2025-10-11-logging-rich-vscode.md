---
layout: single
author_profile: true
read_time: true
toc: true
toc_sticky: true
related: true
classes: wide
title: "使用 logging + rich 美化 VSCode 调试输出"
date: 2025-10-11 00:00:00 +0800
categories: [编程, Python]
tags: [Python, logging, rich, VSCode, 调试, 日志]
permalink: /python-logging-rich-vscode/
---

🌈 使用 logging + rich 美化 VSCode 调试输出

## 一、为什么使用 logging + rich
- logging 是 Python 官方提供的日志系统，支持分级（INFO、WARNING、ERROR 等）和可配置输出。
- rich 可以让日志输出带颜色、时间戳、模块名等信息更易读。
- 两者结合后，你的调试输出比 print() 更强大、更清晰。

## 二、安装
在终端执行：
```bash
pip install rich
```

## 三、基本使用示例
文件名：demo_log_rich.py
```python
from rich.logging import RichHandler
import logging

# 1️⃣ 配置 logging 基础设置
logging.basicConfig(
    level="INFO",  # 日志等级，可选 DEBUG, INFO, WARNING, ERROR, CRITICAL
    format="%(message)s",  # rich 会自动格式化输出，不需要复杂模板
    datefmt="[%X]",  # 时间显示格式，例如 [14:32:05]
    handlers=[RichHandler()]  # 使用 RichHandler 代替默认控制台输出
)

# 2️⃣ 创建 logger 对象
log = logging.getLogger("rich")

# 3️⃣ 打印不同级别的日志
log.debug("这是调试信息（debug），默认不会显示")
log.info("系统启动成功 ✅")
log.warning("⚠️ 资源占用较高，请注意")
log.error("❌ 发生错误：连接超时")
log.critical("🔥 严重错误，系统即将退出")
```

## 四、输出效果（在 VSCode 终端中）
运行后你会看到带颜色和时间戳的输出，例如：
```
[14:32:05] INFO     系统启动成功 ✅
[14:32:05] WARNING  ⚠️ 资源占用较高，请注意
[14:32:05] ERROR    ❌ 发生错误：连接超时
[14:32:05] CRITICAL 🔥 严重错误，系统即将退出
```
颜色和图标帮助你快速识别日志等级。

## 五、在 VSCode 调试中启用彩色日志
VSCode 默认的 “Debug Console” 不显示颜色。需要在 launch.json 中将 console 设置为 integratedTerminal。

打开 .vscode/launch.json：
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Debug with Rich Logging",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal"
    }
  ]
}
```
然后重新点击 “Run and Debug”，就能看到彩色日志了。

## 六、进阶：同时输出到文件与终端
如果你既想在终端看到彩色日志，又想保存纯文本日志，可以这样做：
```python
from rich.logging import RichHandler
import logging

# 文件输出
file_handler = logging.FileHandler("app.log", encoding="utf-8")

# rich 输出
rich_handler = RichHandler(rich_tracebacks=True)

logging.basicConfig(
    level="INFO",
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="[%Y-%m-%d %H:%M:%S]",
    handlers=[file_handler, rich_handler]
)

log = logging.getLogger("app")

log.info("程序启动中...")
log.warning("磁盘空间不足")
log.error("请求接口失败")
```
这样：
- 终端中输出彩色日志；
- app.log 文件中保存纯文本日志。

## 七、进阶：美化异常输出
如果希望异常信息（traceback）也能彩色显示：
```python
from rich.traceback import install
install()  # 安装 rich 的异常追踪美化

# 故意触发一个错误
x = 1 / 0
```
输出会是高亮、带行号的堆栈信息。

## ✅ 总结推荐配置
| 目标 | 推荐做法 |
| --- | --- |
| 彩色终端日志 | logging + RichHandler() |
| 彩色异常信息 | from rich.traceback import install() |
| VSCode 调试时有颜色 | "console": "integratedTerminal" |
| 同时保存日志文件 | handlers=[FileHandler, RichHandler] |
