<div align="center">

# 🛡️ cf5sSolver

**Cloudflare 验证自动化处理服务**

[![Docker](https://img.shields.io/badge/Docker-支持-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Linux](https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux&logoColor=black)](https://www.linux.org/)
[![License](https://img.shields.io/badge/License-合法用途-green)](#-合规声明)
[![Telegram](https://img.shields.io/badge/联系作者-Telegram-26A5E4?logo=telegram&logoColor=white)](https://t.me/yoyoCrafts)

</div>

---

> **⚠️ 法律声明 / Legal Disclaimer**
>
> 本工具仅供**合法用途**使用，包括：自动化测试、学术研究、安全审计等。
> **严禁用于任何违法行为**，包括但不限于：绕过安全机制进行恶意攻击、未授权访问系统、网络欺诈等。
> 使用本工具即表示您同意遵守所在地区的法律法规，开发者对任何滥用行为不承担责任。

---





## 💡 简介

**cf5sSolver** 是一个基于浏览器的验证码处理服务，支持 Cloudflare 5秒盾及 Turnstile 人机验证的自动化处理。适用于需要在受保护页面进行合法自动化操作的开发者和测试人员。

| 特性 | 说明 |
|------|------|
| ✅ **Cloudflare 5秒盾** | 自动处理 CF Under Attack Mode 验证 |
| ✅ **Turnstile 人机验证** | 支持 Turnstile 插件验证并返回 Token |
| 🔄 **静态内容缓存** | 缓存静态资源，大幅节约流量开销 |
| 🌐 **代理支持** | 支持 HTTP / HTTPS 代理及认证 |

---

## 🚀 快速开始

> **环境要求：** 已安装 Docker 及 Docker Compose，**目前仅支持 Linux 环境运行 需要注意的是并行数量最好是不要超过CPU线程数**。

```bash
# 1. 克隆项目
git clone https://github.com/ipaguge/cf5sSolver.git

# 2. 进入目录并启动服务
cd cf5sSolver && docker compose up -d
```

服务启动后默认监听 `http://localhost:8901`。

---

## 📚 API 文档

### Cloudflare 5秒盾验证

```
POST /cloudflare
```

```bash
curl -X POST http://localhost:8901/cloudflare \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://core.particle.network/cloudflare.html",
    "proxy": {
      "url": "http://gw.dataimpulse.com:12000",
      "username": "your_username",
      "password": "your_password"
    },
    "timeout": 90,
    "retryOnFailure": 2,
    "outputBody": false,
    "outputDelay": 0
  }'
```

---

### Turnstile 人机验证

```
POST /turnstile
```

```bash
curl -X POST http://localhost:8901/turnstile \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://core.particle.network/cloudflare.html",
    "proxy": {
      "url": "http://gw.dataimpulse.com:12000",
      "username": "your_username",
      "password": "your_password"
    },
    "timeout": 90,
    "retryOnFailure": 2,
    "outputBody": false,
    "outputDelay": 0
  }'
```

---

### 请求参数

| 参数名 | 类型 | 必填 |   默认值   | 说明 |
|--------|------|:----:|:-------:|------|
| `url` | `string` | ✅ |    —    | 目标验证页面 URL |
| `proxy.url` | `string` | ❌ |    —    | 代理地址，格式：`http://host:port` |
| `proxy.username` | `string` | ❌ |    —    | 代理认证用户名 |
| `proxy.password` | `string` | ❌ |    —    | 代理认证密码 |
| `timeout` | `number` | ❌ |  `100`  | 超时时间（秒） |
| `retryOnFailure` | `number` | ❌ |   `0`   | 失败自动重试次数 |
| `outputBody` | `boolean` | ❌ | `false` | 是否返回页面 Body 内容 |
| `outputDelay` | `number` | ❌ |   `0`   | 输出延迟（毫秒） |

---

### 响应格式

#### ✅ 成功

```json
{
  "status": "success",
  "message": "",
  "data": {
    "isVerifyPage": true,
    "userAgent": "Mozilla/5.0 (Linux; Android 12; ...)",
    "cookies": "cf_clearance=abc123...",
    "turnstileToken": "0.abc123...",
    "body": ""
  }
}
```

#### ❌ 失败

```json
{
  "status": "failure",
  "message": "验证超时，请检查目标 URL 或代理配置",
  "data": null
}
```

#### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | `string` | 请求状态：`success` / `error` |
| `message` | `string` | 错误描述（成功时为空） |
| `data.isVerifyPage` | `boolean` | 是否检测到验证页面 |
| `data.userAgent` | `string` | 本次请求使用的 User-Agent |
| `data.cookies` | `string` | 验证通过后获取的 Cookie |
| `data.turnstileToken` | `string` | Turnstile 验证 Token |
| `data.body` | `string` | 页面 Body（需启用 `outputBody`） |

---



## 📌 闭源说明

> 本项目**并非开源项目**（源代码不公开），但**部署和使用没有任何限制**，您可以自由下载、运行、停止或卸载。  
> **不开源的原因**：为了保护核心绕过算法的稳定性，避免因算法细节公开而被 Cloudflare 针对性封控，从而影响所有用户的正常使用。  
> 我们相信“闭源但不限制使用”是对大家最负责任的方式。感谢您的理解与支持！

---

## 📬 联系方式

如有验证实效、建议或定制需求，欢迎通过以下方式联系：

<div align="center">

[![Telegram](https://img.shields.io/badge/Telegram-联系我-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/yoyoCrafts)

*也可以提交 Issue，我会尽快回复。*

</div>

---



