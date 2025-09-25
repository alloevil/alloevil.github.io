---
layout: post
title: 使用 GPT-5 接管 CCR
date: 2025-09-25
tags: [essy]
---

## 背景
由于公司内部已无法使用 Claude，原有依赖 Claude Code Router (CCR) 的工作流也无法继续使用。为了保持研发工具链的连续性，需要寻找替代方案。经过探索，确认可以通过 GPT-5 + Claude Code Router + 自定义 transformer 来实现替代。

（关于 Claude Code Router 的安装方法，请参考 claude code router 项目中的安装方法，这里不再赘述。）

## 整体思路
- 在 Azure OpenAI 上创建 GPT-5 部署并获取 API Key
- 修改 CCR 的配置文件
- 通过自定义 transformer，为请求添加额外 Header，并结合内置 transformer（如 maxcompletiontokens）
- 验证 Azure OpenAI 的 GPT-5 模型能够正常响应

## 实现步骤
### 3.1 生成 GPT-5 API Key
在 Azure OpenAI 门户中创建 GPT-5 部署（如 gpt-5-chat），并获取 API Key。

### 3.2 配置 Claude Code Router
在 ~/.claude-code-router/config.json 中新增 provider 配置，指向 Azure OpenAI Chat Completions 接口。

### 3.3 新增自定义 Transformer
新建 header.js 文件，放在指定路径（如 /home/Downloads/header.js），用于自动附加额外请求头。

## 配置文件示例
```json
{
  "Providers": [
    {
      "name": "azure_openai",
      "api_base_url": "https://your-resource-name.openai.azure.com/openai/deployments/gpt-5-chat/chat/completions?api-version=2025-04-01-preview",
      "api_key": "sk-xxx",
      "models": [
        "gpt-5"
      ],
      "transformer": {
        "use": [
          "header",
          "maxcompletiontokens"
        ]
      }
    }
  ],
  "transformers": [
    {
      "name": "header",
      "path": "/home/Downloads/header.js",
      "options": {}
    }
  ],
  "Router": {
    "default": "azure_openai,gpt-5"
  },
  "LOG": true,
  "LOG_LEVEL": "info"
}
```

header.js 示例：
```js
class HeaderTransformer {
    name = "header";
    constructor(options = {}) { this.options = options; }
    async transformRequestIn(request, provider) {
        request.temperature = 1;
        if (request && Object.prototype.hasOwnProperty.call(request, "reasoning")) {
            delete request.reasoning;
            request.reasoning_effort = "high";
            request.verbosity = "high";
        }
        return {body: request,config: {headers: {'X-Model-Provider-Id': 'azure_openai'
                },
            },
        };
    }
}

module.exports = HeaderTransformer;
```

## 注意事项
- 本方案在 Azure OpenAI 的 GPT-5 模型上验证通过，其它模型尚未测试
- header.js 的路径为绝对路径
- 如果网关接口需要更多自定义 Header，可以在 transformer 中继续扩展

## 总结
通过在 Azure OpenAI 上创建 GPT-5 部署并获取 API Key，结合 Claude Code Router 与自定义 transformer，可以在公司环境下顺利替代 Claude，实现现有工作流的延续。此方案对代码改动较少，主要依赖配置调整与少量 transformer 扩展，适合团队快速落地。
