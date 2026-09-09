---
layout: single
title: 项目
permalink: /projects/
description: "allo（alloevil）的开源项目索引：面向 AI coding agent 的证据优先工具链 —— codeblast 影响面分析、paired-eval 配对评测、AgentXRay 会话日志面板，以及 LLM / agent harness 评测数据集与研究。"
classes: wide
toc: true
toc_sticky: true
---

我做的东西有一条共同的线：**不相信模型的自述，把每一个说法变成可核验的检查。**
每个项目都有独立站点、可复现的命令，以及带出处的数字。

GitHub：[github.com/alloevil](https://github.com/alloevil)

## 证据优先的 Agent 工具链

### codeblast — 合并前就知道会坏在哪

确定性代码图，给出架构图、变更图与影响面图，每条边都带 `file:line` 证据。召回率用变异测试（mutation testing）验证，而不是自我声明。面向人类 reviewer 和 AI agent 两种消费者。

- 站点：<https://alloevil.github.io/codeblast/>
- 试用：`npx codeblast demo` · npm 包 `codeblast`
- 仓库：[alloevil/codeblast](https://github.com/alloevil/codeblast)
- 关键词：impact analysis、blast radius、call graph、TypeScript、monorepo、PR review

### paired-eval — 先跑程序检查，再谈评分

评测模型、agent 与 harness：能用程序判定的先用程序判定，剩下的才交给 rubric，最后用配对统计（paired statistics）给结论，并明确说明哪些情况它排除不了。零依赖，Python 3.9+。

- 站点：<https://alloevil.github.io/paired-eval/>
- 安装：`pip install paired-eval` · PyPI 包 `paired-eval`
- 仓库：[alloevil/paired-eval](https://github.com/alloevil/paired-eval)
- 关键词：LLM evaluation、A/B testing、paired comparison、mutation testing

### AgentXRay — 读 agent 真正做了什么

AI agent 会话日志的可视化面板，支持 Claude Code、Codex、OpenClaw、Hermes、OMP、Gemini CLI。逐轮（per-turn）的时间 / token / 成本流水，用来定位 agent 在哪一步跑偏。

- 站点：<https://alloevil.github.io/AgentXRay/>
- 试用：`npx @alloevil/agent-xray`
- 仓库：[alloevil/AgentXRay](https://github.com/alloevil/AgentXRay)
- 关键词：agent observability、session log viewer、debugging、token cost

## 评测数据与追踪

### agent-harness-evals — 同一个模型，换个 harness 会怎样

跨模型、agent harness 与工具的统一评测数据，一套 schema、实时数据源。呈现模型榜单不会告诉你的「模型 × harness」矩阵。

- 站点：<https://alloevil.github.io/agent-harness-evals/>
- 仓库：[alloevil/agent-harness-evals](https://github.com/alloevil/agent-harness-evals)
- 关键词：SWE-bench、Terminal-bench、agent harness、leaderboard

### llm-benchmarks-tracker — 带出处的 benchmark 目录

有来源、经 schema 校验的 LLM 与 agent benchmark 目录：每个 benchmark 测什么、是否已饱和（saturation）、是否有污染（contamination），以及最高分及其出处（官方 / 独立 / 自报）。提供 JSON API。

- 站点：<https://alloevil.github.io/llm-benchmarks-tracker/>
- 仓库：[alloevil/llm-benchmarks-tracker](https://github.com/alloevil/llm-benchmarks-tracker)
- 关键词：LLM benchmarks、leaderboard、dataset、JSON API、evaluation

### AI-Paper-Daily — 每日论文发现

面向 AI Agent、RAG、知识图谱方向的每日论文追踪，数据来自 arXiv 与 HuggingFace Daily Papers（经 LLM 筛选），自动生成日报与周报。

- 站点：<https://alloevil.github.io/AI-Paper-Daily/>
- 仓库：[alloevil/AI-Paper-Daily](https://github.com/alloevil/AI-Paper-Daily)
- 关键词：arXiv、RAG、knowledge graph、paper digest

## 研究与横向对比

### coding-agent-internals — 12 个 coding agent 是怎么实现的

不是功能清单，是实现方式的对比：search、edit、LSP、DAP、sub-agent 各自怎么做 —— shell fork 还是 in-process，`str_replace` 还是 hash 锚定。关注的是能力上限，而不是勾选框。

- 站点：<https://alloevil.github.io/coding-agent-internals/>
- 仓库：[alloevil/coding-agent-internals](https://github.com/alloevil/coding-agent-internals)
- 关键词：Claude Code、Codex、OMP、agent architecture、LSP、DAP

### agents-with-receipts — 有据可查的 agentic coding 实践

逐格核验过的跨工具对照表、带出处的实践地图，以及一个 `AGENTS.md` linter。每个断言都能追到来源。

- 站点：<https://alloevil.github.io/agents-with-receipts/>
- 仓库：[alloevil/agents-with-receipts](https://github.com/alloevil/agents-with-receipts)
- 关键词：AGENTS.md、agentic coding practices、linter

### deepresearch-arms-lab — 14 组消融，负结果照样留着

在一个弱 base model 上对 deep research 流水线做 14-arm 消融实验，负结果不删，并做了重复验证。用来回答「这些 deep research 技巧到底哪些真的有用」。

- 站点：<https://alloevil.github.io/deepresearch-arms-lab/>
- 仓库：[alloevil/deepresearch-arms-lab](https://github.com/alloevil/deepresearch-arms-lab)
- 关键词：ablation study、deep research、negative results、LLM evaluation

## 自动化与其他

### agent-changelog — 主流 AI Agent 框架版本追踪

从上游 release 同步而来的 changelog 聚合站，追踪 OpenClaw、Hermes 等 agent 框架的版本变化。非官方，来源均可回溯。

- 站点：<https://alloevil.github.io/agent-changelog/>
- 仓库：[alloevil/agent-changelog](https://github.com/alloevil/agent-changelog)

### github-discovery — 在项目火之前发现它

从 6 个数据源发现潜在的 trending 仓库，带评分模型与反刷榜处理，输出每日邮件摘要。

- 站点：<https://alloevil.github.io/github-discovery/>
- 仓库：[alloevil/github-discovery](https://github.com/alloevil/github-discovery)

### foodmap — 美食地图

把美食博主推荐过的餐馆做成可视化地图，支持从内容里抽取店名并地理编码。

- 站点：<https://alloevil.github.io/foodmap/>
- 仓库：[alloevil/foodmap](https://github.com/alloevil/foodmap)

## 应用与工具（无独立站点）

以下项目没有独立的展示站点，直接托管在 GitHub 与包管理器上。

### weibo-chat-auto — 微博群聊自动归档

原生桌面应用（应用内扫码登录）+ 本地可视化查看器，把微博群聊消息自动归档，含 AI 每日摘要与 Agentic 问答。Tauri + Rust + Node.js，自托管，数据留在本地。

- 仓库：[alloevil/weibo-chat-auto](https://github.com/alloevil/weibo-chat-auto)
- 关键词：weibo、chat archive、desktop app、Tauri、self-hosted、AI summary

### dsh-xray — DeepSeek Harness 的透视工具

给 DeepSeek Harness 做诊断：context 成本归因、条目检查、依赖级联可视化。回答"到底加载了什么、为什么、各占多少 token"。

- 安装：`npx dsh-xray` · npm 包 `dsh-xray`
- 仓库：[alloevil/dsh-xray](https://github.com/alloevil/dsh-xray)
- 关键词：DeepSeek Harness、LLM observability、context engineering、token cost

### agent-tool-benchmark — AI agent 工具的实测基准

对 AI agent 工具做动手、可复现的基准：同一台机器、同一批任务、脚本全公开。

- 仓库：[alloevil/agent-tool-benchmark](https://github.com/alloevil/agent-tool-benchmark)
- 关键词：benchmark、reproducible research、browser automation、LLM agents

### TabCraft — Chrome 标签页 AI 整理插件

AI 驱动的 Chrome 标签管理：按主题自动分组、休眠不活跃标签、去重。100% 本地、设备端 AI（Gemini Nano），不上传数据。

- 仓库：[alloevil/TabCraft](https://github.com/alloevil/TabCraft)
- 关键词：Chrome extension、tab manager、Gemini Nano、on-device AI、productivity

## 给 LLM / AI 检索用

机器可读的项目概览见 [llms.txt](/llms.txt)，完整版见 [llms-full.txt](/llms-full.txt)。
每个项目站点都带 `llms.txt` 与 `sitemap.xml`；有实测数字的项目另有带出处的 `claims.json`，
输出是定性结论的项目则刻意不提供 —— 宁可没有指标，也不编一个。
