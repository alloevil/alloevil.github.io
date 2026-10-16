---
layout: single
author_profile: true
read_time: true
toc: true
toc_sticky: true
related: true
classes: wide
title: "从零部署 Xray REALITY：Clash DNS 防泄露、Google GeoIP 与 Gemini/HomeIP 排障实录"
date: 2026-10-16 00:00:00 +0900
categories: [网络, 运维]
tags: [Xray, VLESS, REALITY, XTLS, Clash Verge Rev, Mihomo, DNS, Gemini, HomeIP, BBR]
permalink: /xray-reality-clash-dns-gemini-homeip/
---

这篇文章记录一次完整的自建代理部署与排障过程：在 Ubuntu VPS 上通过官方脚本安装 Xray-core，配置 `VLESS + REALITY + XTLS Vision`，在 macOS 上使用 Clash Verge Rev 做国内外分流，并处理 DNS 泄露与 Google GeoIP 误判。最后，由于 Google 将整个 VPS 网段错误识别为中国，我将 Gemini 单独切换到 HomeIP 出口。

本文重点不只是“复制命令”，而是每一步如何验证，以及遇到问题后怎样区分服务端、客户端、DNS 和目标网站自身的地区数据库。

> 本文仅用于合法的自建网络、隐私保护和运维研究。请遵守所在地法律法规、云服务商条款和目标服务条款。文中所有地址与凭据均为占位符，请勿把真实 UUID、私钥、Short ID、订阅 URL 或账户凭据提交到公开仓库。

## 一、最终架构

最终流量分为三类：

```text
                         ┌─ 中国域名 / 中国 IP
                         │  DIRECT + 国内 DoH
Mac / iPhone ─ Clash ────┤
                         ├─ 普通国外流量
                         │  RackNerd VPS → Xray REALITY
                         │
                         └─ Gemini / Google AI
                            HomeIP 专用出口
```

选择这套结构的原因：

- 国内流量直连，避免不必要的跨境绕路；
- 普通国外流量使用自己的 VPS，控制力更强；
- Gemini 对 IP 地区和信誉的判断与普通 GeoIP 数据库不同，因此单独使用 HomeIP；
- DNS 根据域名类别选择解析器，避免“网页走代理、DNS 仍在本地”的泄露。

## 二、环境与目标

这次使用的环境如下：

| 组件 | 环境 |
| --- | --- |
| VPS | Ubuntu 24.04 LTS，约 1 GB RAM |
| 服务端 | Xray-core 26.x |
| 安装器 | XTLS 官方 Xray-install |
| 协议 | VLESS + REALITY + XTLS Vision |
| 传输 | TCP/RAW 443 |
| macOS 客户端 | Clash Verge Rev 2.5.x / Mihomo 1.19.x |
| iOS 客户端 | Shadowrocket |
| 拥塞控制 | BBR + fq |

对于个人使用，1 GB RAM 已经足够。实际体验更依赖线路、晚高峰拥塞、IP 信誉和服务商端口策略，而不是磁盘或 CPU。

## 三、先配置 SSH 密钥登录

### 3.1 生成密钥

macOS 上优先使用 Ed25519：

```bash
ssh-keygen -t ed25519 -a 100
```

默认会生成：

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

私钥 `id_ed25519` 只能留在本机，服务器只保存 `.pub` 公钥。

### 3.2 安装公钥

把 `<VPS_IP>` 换成服务器地址：

```bash
cat ~/.ssh/id_ed25519.pub | ssh root@<VPS_IP> \
  'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'
```

这一步需要最后输入一次服务器密码。随后测试：

```bash
ssh -o BatchMode=yes -o IdentitiesOnly=yes \
  -i ~/.ssh/id_ed25519 root@<VPS_IP> 'id -un && hostname'
```

确认免密登录成功后，再考虑关闭 SSH 密码认证。不要在密钥尚未验证时关闭密码登录，否则容易把自己锁在服务器外。

## 四、使用官方脚本安装 Xray-core

项目地址：

- [XTLS/Xray-core](https://github.com/XTLS/Xray-core)
- [XTLS/Xray-install](https://github.com/XTLS/Xray-install)

我没有直接执行未知的一键脚本，而是先下载并检查语法：

```bash
curl -fsSL -o /tmp/xray-install.sh \
  https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh

bash -n /tmp/xray-install.sh
sha256sum /tmp/xray-install.sh
```

确认来源和脚本无误后执行：

```bash
bash /tmp/xray-install.sh install
```

官方脚本会安装：

```text
/usr/local/bin/xray
/usr/local/etc/xray/config.json
/usr/local/share/xray/geoip.dat
/usr/local/share/xray/geosite.dat
/etc/systemd/system/xray.service
```

检查版本和服务：

```bash
xray version
systemctl is-enabled xray
systemctl is-active xray
```

### 4.1 使用仓库脚本快速部署

为了以后更换 VPS 或在备用节点上重复部署，我把上述过程整理成了脚本：

- [deploy-xray-reality.sh]({{ '/assets/scripts/deploy-xray-reality.sh' | relative_url }})

建议先下载并审阅，不要直接 `curl | bash`：

```bash
curl -fsSL -o deploy-xray-reality.sh \
  https://raw.githubusercontent.com/alloevil/alloevil.github.io/master/assets/scripts/deploy-xray-reality.sh

less deploy-xray-reality.sh
bash -n deploy-xray-reality.sh
```

在全新的 Ubuntu VPS 上执行：

```bash
sudo bash deploy-xray-reality.sh --address <VPS_IP>
```

常用选项：

```text
--port <PORT>       修改 Xray 监听端口，默认 443
--target <DOMAIN>   修改 REALITY 目标和 SNI，默认 www.apple.com
--no-bbr            跳过 BBR + fq
--force             备份并替换已有 Xray 配置
```

脚本完成后会把客户端参数保存到：

```text
/root/xray-client-info.txt
```

该文件权限为 `600`，包含完整客户端链接，不应上传到 GitHub 或发送给不可信的人。

如果服务器已有配置，脚本默认停止。只有明确需要轮换 UUID、REALITY 密钥和 Short ID 时才使用 `--force`；执行后旧客户端会立即失效，需要全部重新导入。

脚本不会自动修改 SSH、UFW、云安全组或服务商后台规则。TCP 443 仍需在云防火墙中单独放行。

## 五、配置 VLESS + REALITY + XTLS Vision

### 5.1 生成参数

生成 UUID：

```bash
xray uuid
```

生成 REALITY X25519 密钥：

```bash
xray x25519
```

新版本可能输出：

```text
PrivateKey: <REALITY_PRIVATE_KEY>
Password (PublicKey): <REALITY_PUBLIC_KEY>
Hash32: ...
```

服务端使用私钥，客户端只使用公钥。不要把私钥发给客户端或写进公开文档。

生成 Short ID：

```bash
openssl rand -hex 8
```

### 5.2 服务端配置

将 `/usr/local/etc/xray/config.json` 配置为：

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vless-reality-in",
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "<UUID>",
            "flow": "xtls-rprx-vision",
            "email": "personal"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "raw",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "target": "www.apple.com:443",
          "xver": 0,
          "serverNames": [
            "www.apple.com"
          ],
          "privateKey": "<REALITY_PRIVATE_KEY>",
          "shortIds": [
            "<SHORT_ID>"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "blocked",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
}
```

这里阻止了代理访问私有网段，并禁用 BitTorrent，降低误用、SSRF 和投诉风险。

### 5.3 先校验，再重启

```bash
xray run -test -config /usr/local/etc/xray/config.json
systemctl restart xray
systemctl status xray --no-pager
ss -ltnp 'sport = :443'
```

正确结果应包含：

```text
Configuration OK
active (running)
LISTEN *:443
```

还可以从客户端机器测试 REALITY 的未认证回落行为：

```bash
openssl s_client \
  -connect <VPS_IP>:443 \
  -servername www.apple.com \
  -verify_return_error </dev/null
```

如果返回 Apple 的有效 TLS 1.3 证书，说明 443、公网安全组和 REALITY 回落路径都正常。

## 六、启用 BBR + fq

先确认内核支持：

```bash
modinfo tcp_bbr
sysctl net.ipv4.tcp_available_congestion_control
```

加载模块：

```bash
modprobe tcp_bbr
```

持久化模块加载：

```bash
printf '%s\n' 'tcp_bbr' > /etc/modules-load.d/xray-bbr.conf
```

创建 `/etc/sysctl.d/99-xray-network.conf`：

```text
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
```

即时应用：

```bash
sysctl -w net.core.default_qdisc=fq
sysctl -w net.ipv4.tcp_congestion_control=bbr
```

验证：

```bash
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_congestion_control
ss -tin
```

旧 TCP 连接仍可能显示 `cubic`，新连接才会显示 `bbr`。为确保 Xray 的监听套接字在新默认值下创建，我最后重启了一次 Xray。

BBR 可以改善高延迟链路的拥塞恢复，但无法解决 VPS 超售、线路绕路或晚高峰带宽不足。

## 七、Shadowrocket 与 Clash 客户端参数

### 7.1 Shadowrocket

核心参数如下：

```text
类型：VLESS
地址：<VPS_IP>
端口：443
UUID：<UUID>
传输：TCP
流控：xtls-rprx-vision
TLS/安全：REALITY
SNI：www.apple.com
指纹：chrome
Public Key：<REALITY_PUBLIC_KEY>
Short ID：<SHORT_ID>
允许不安全：关闭
```

Shadowrocket 新版本不一定显示一个单独名为“REALITY”的节点类型。只要节点类型为 VLESS，并出现 Public Key、Short ID、SNI 和指纹字段，就已经识别了 REALITY。

### 7.2 Clash/Mihomo 节点

```yaml
proxies:
  - name: RackNerd-Reality
    type: vless
    server: <VPS_IP>
    port: 443
    uuid: <UUID>
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: www.apple.com
    client-fingerprint: chrome
    reality-opts:
      public-key: <REALITY_PUBLIC_KEY>
      short-id: <SHORT_ID>
```

客户端参数必须与服务端完全对应。SNI、公钥或 Short ID 任一不一致，都会导致握手失败。

## 八、Clash Verge Rev 的国内外 DNS 分流

### 8.1 为什么“同时写国内外 DNS”仍会泄露

最初的配置同时查询国内 DNS 和 Google/Cloudflare DoH。网页出口虽然是美国，但 DNS 检测仍能看到中国电信和 CNISP 的解析器。

原因是 Mihomo 会并发查询多个默认 nameserver，谁先返回就使用谁；即使最终选用了海外结果，中国 DNS 查询也已经发生，权威 DNS 检测站仍能看到它。

正确做法不是“多写几个 DNS”，而是通过 `nameserver-policy` 决定不同域名只能查询哪一组解析器。

### 8.2 最终 DNS 配置

下面是一份脱敏后的通用版本：

```yaml
dns:
  enable: true
  listen: :53
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  ipv6: false
  prefer-h3: false
  respect-rules: true
  use-hosts: true
  use-system-hosts: false

  default-nameserver:
    - 223.5.5.5
    - 119.29.29.29

  # 直连的中国域名使用国内加密 DNS
  direct-nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query
  direct-nameserver-follow-policy: true

  # 未分类域名默认走海外 DoH，避免随机测试域名触发国内 DNS
  nameserver:
    - https://8.8.8.8/dns-query
    - https://1.1.1.1/dns-query

  fallback:
    - https://8.8.8.8/dns-query
    - https://1.1.1.1/dns-query

  # 解析代理节点域名，避免“必须先连代理才能解析代理”的循环
  proxy-server-nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query

  nameserver-policy:
    geosite:cn:
      - https://doh.pub/dns-query
      - https://dns.alidns.com/dns-query
    geosite:geolocation-!cn:
      - https://8.8.8.8/dns-query
      - https://1.1.1.1/dns-query

  fake-ip-filter-mode: blacklist
  fake-ip-filter:
    - '*.lan'
    - '*.local'
    - '*.arpa'
    - geosite:private
    - geosite:cn
```

这套策略的取舍是：

- 中国域名返回真实 IP，兼容国内 App、支付和局域网；
- 国外域名使用 Fake-IP，由 Clash 完成映射；
- 未分类域名默认使用海外 DoH，优先保证隐私；
- 极少数没有被 GeoSite 收录的国内域名可能通过海外 DNS 解析，速度会稍慢，但流量仍可按规则直连。

### 8.3 TUN 必须实际启用

配置文件写着 `tun.enable: true` 不代表运行时一定生效。应当通过 Mihomo API 或 Clash Verge Rev 界面检查运行状态。

```yaml
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true
  dns-hijack:
    - any:53
```

macOS 如果手动指定了一个落在 TUN 排除网段中的企业 DNS，该 DNS 会绕过 `any:53`。我的解决方式是给 Wi-Fi 配置一个能被 TUN 捕获、Clash 关闭时也能正常使用的公共 DNS：

```bash
networksetup -setdnsservers Wi-Fi 223.5.5.5 119.29.29.29
dscacheutil -flushcache
```

### 8.4 一处语法错误如何让整个配置失效

排障时还遇到一个容易忽略的问题：`nameserver-policy` 中原本存在类似下面的键：

```yaml
+example.cn:
  - 10.0.0.53
```

Mihomo 要求 `+` 通配符占据完整标签。应改成精确域名：

```yaml
example.cn:
  - 10.0.0.53
```

或者合法的子域通配：

```yaml
+.example.cn:
  - 10.0.0.53
```

这一个错误会导致最终配置验证失败。Clash Verge Rev 会退回最小配置启动，表现为：界面还开着，但 TUN 和 DNS section 实际关闭，流量可能直接连接。

因此每次修改后都要检查应用日志和运行时状态，而不是只看 YAML 是否能被普通解析器读取。

## 九、验证 DNS 是否真的修好

### 9.1 本地解析行为

```bash
dig +short www.google.com A
dig +short www.baidu.com A
```

预期结果：

```text
Google → 198.18.0.0/16 内的 Fake-IP
百度   → 真实中国 IP
```

这说明国外域名被 Clash 接管，国内域名仍保持真实解析。

### 9.2 网页深度检测

我使用了：

```text
https://ip.net.coffee/dns/
```

第一次检测同时出现 Google/Cloudflare 和中国电信/CNISP，说明虽然海外 DNS 已启用，但国内 nameserver 仍被并发查询。

将默认 nameserver 改为海外 DoH，仅让 `geosite:cn` 使用国内 DoH 后，深度检测结果变成：

```text
出口 IP：美国 VPS
DNS 解析器：Google / Cloudflare 美国节点
中国 DNS：0
结论：未检测到 DNS 泄露
```

注意，公共 DNS 的出口 IP 不需要等于 VPS IP。判断重点是它是否仍暴露本地运营商和真实地区。

## 十、Google GeoIP：第三方显示美国，Google 却显示武汉

DNS 修复后，Google 搜索页底部仍然显示：

```text
Wuhan, Hubei, China — From your IP address
```

而常见 IP 数据库将 VPS 判断为美国 Dallas（换 IP 后 ipinfo 显示为 Los Angeles）。登录 Gemini 后则提示：

```text
Gemini isn’t currently supported in your country.
```

为了排除分流错误，我检查了 Mihomo 的活动连接。所有 Google 请求都经过：

```text
gemini.google.com → RackNerd-Reality → Proxy → Manual
accounts.google.com → RackNerd-Reality → Proxy → Manual
googleapis.com → RackNerd-Reality → Proxy → Manual
gstatic.com → RackNerd-Reality → Proxy → Manual
```

所以这不是 DNS 泄露或 Google 域名直连，而是 Google 自己的 GeoIP 数据与第三方数据库不一致。

### 10.1 为什么换相邻 IP 没用

我把 VPS IP 换成了同一网段中的另一个地址。第三方数据库仍显示美国，但 Google 继续判断为武汉。

原因很可能是 Google 按整个 `/24` 网段维护位置。只改最后一个数字，仍然落在同一个地址块中。

如果要求云厂商换 IP，应明确说明：

```text
Please assign an IP from a completely different /24 subnet.
The current subnet is incorrectly geolocated by Google as China.
```

换到不同 `/24`，最好再换 ASN 或机房，才有机会改变 Google 的判断。

### 10.2 Google 搜索位置不是通用 GeoIP 真值

Google 没有公开一个可输入任意 IP 的 GeoIP 查询页面。最接近 Google 自身判断的方法，是在无痕窗口拒绝定位权限后打开：

```text
https://www.google.com/search?q=where+am+i&hl=en&pws=0
```

查看页面底部的 `From your IP address`。但最终仍要以登录后的 Gemini 能否对话为准。

## 十一、最终通过 HomeIP 解决 Gemini

由于自建 VPS 的整个网段都被 Google 误判，我最终没有继续修改 DNS、REALITY 或浏览器指纹，而是使用 HomeIP 作为 Gemini 的专用出口。

核心原则是：同一 Google 会话相关的域名尽量使用同一个出口，避免登录请求、Gemini 页面和 API 来自不同国家。

在 Clash 中可以建立一个独立策略组：

```yaml
proxy-groups:
  - name: Gemini
    type: select
    proxies:
      - <HOMEIP_NODE>
      - RackNerd-Reality
```

然后把 Gemini 相关域名放在中国直连和默认规则之前：

```yaml
rules:
  - DOMAIN,gemini.google.com,Gemini
  - DOMAIN,aistudio.google.com,Gemini
  - DOMAIN,ai.google.dev,Gemini
  - DOMAIN,accounts.google.com,Gemini
  - DOMAIN,ogs.google.com,Gemini
  - DOMAIN-SUFFIX,gemini.gstatic.com,Gemini
  - DOMAIN-SUFFIX,generativelanguage.googleapis.com,Gemini
  - DOMAIN-SUFFIX,googleapis.com,Gemini
  - DOMAIN-SUFFIX,gstatic.com,Gemini
  - DOMAIN-SUFFIX,googleusercontent.com,Gemini

  - GEOSITE,private,DIRECT
  - GEOSITE,cn,DIRECT
  - GEOIP,private,DIRECT,no-resolve
  - GEOIP,CN,DIRECT
  - MATCH,Manual
```

实际依赖域名会随 Google 产品更新。如果仍出现地区不一致，应查看 Mihomo 活动连接，确认所有 Gemini 会话域名都经过同一策略组。

HomeIP 解决的是“目标服务对出口 IP 的地区/信誉要求”，不是 DNS 泄露。两者不能混为一谈：

- DNS 泄露：本地运营商能看到查询，靠 TUN、DoH 和 nameserver-policy 修复；
- GeoIP 误判：目标服务认为出口 IP 属于错误国家，通常只能更换出口；
- 账户地区：与 Cookie、付款资料和 Google 账户历史有关，需要单独验证。

使用第三方出口时也要理解隐私边界：HTTPS 内容仍然加密，但提供商可以看到连接目标和流量元数据。因此我只让 Gemini/Google AI 使用 HomeIP，其余流量继续走自建 VPS。

## 十二、服务端链式代理：把住宅 IP 挂在 VPS 后面

### 12.1 为什么在服务端做

客户端方案（在 Clash 里写 `dialer-proxy` 链式节点）也能用，但每台设备都要单独配一遍，iPhone 上的小火箭、家里的路由器还得各写一套。服务端方案只在 VPS 上配一次，所有连到这台 VPS 的客户端（Clash、小火箭、路由器）都自动生效，客户端订阅一行都不用改。

| | 客户端链式（Clash） | 服务端链式（VPS） |
|---|---|---|
| 配置次数 | 每台设备一次 | 一次 |
| 覆盖范围 | 只有配了的设备 | 全部设备 |
| 住宅 IP 凭据 | 分散在每个客户端 | 只存在 VPS 上 |
| 灵活度 | 每台设备可以不同 | 所有设备规则统一 |

流量路径：`客户端 → VPS（Reality / Hysteria2）→ 住宅 IP（SOCKS5）→ Google / AI 网站`，其他流量照旧 `客户端 → VPS → 直出`。

### 12.2 先确认住宅代理的协议

在 VPS 上分别用 SOCKS5 和 HTTP 测一下，哪个有返回就用哪个：

```bash
curl -s -m 15 -x socks5h://<RESI_USER>:<RESI_PASS>@<RESI_HOST>:<RESI_PORT> https://ipinfo.io/json
curl -s -m 15 -x http://<RESI_USER>:<RESI_PASS>@<RESI_HOST>:<RESI_PORT>    https://ipinfo.io/json
```

我这家只有 SOCKS5 有返回，`ip` 是住宅 IP，`city` 是 Mesa, Arizona。

### 12.3 xray：加一个 resi outbound

`/usr/local/etc/xray/config.json` 的 `outbounds` 里加一个 tag 为 `resi` 的出站，`direct` 仍然放在第一个，作为默认出口：

```json
"outbounds": [
  { "tag": "direct",  "protocol": "freedom" },
  { "tag": "blocked", "protocol": "blackhole" },
  {
    "tag": "resi",
    "protocol": "socks",
    "settings": {
      "servers": [{
        "address": "<RESI_HOST>",
        "port": <RESI_PORT>,
        "users": [{ "user": "<RESI_USER>", "pass": "<RESI_PASS>" }]
      }]
    }
  },
  { "tag": "block", "protocol": "blackhole" }
]
```

`routing.rules` 里按域名把 Google 和 AI 网站分到 `resi`（YouTube 规则见下一节，必须放在它前面）：

```json
{
  "type": "field",
  "domain": [
    "domain:google.com", "domain:googleapis.com", "domain:gstatic.com",
    "domain:googleusercontent.com", "domain:gmail.com", "domain:google.dev",
    "domain:openai.com", "domain:chatgpt.com", "domain:oaistatic.com", "domain:oaiusercontent.com",
    "domain:anthropic.com", "domain:claude.ai", "domain:claude.com",
    "domain:ipinfo.io"
  ],
  "outboundTag": "resi"
}
```

`ipinfo.io` 是故意加进去的，方便验证。改完先测再重启：

```bash
xray run -test -c /usr/local/etc/xray/config.json
systemctl restart xray && systemctl is-active xray
```

### 12.4 Hysteria2：outbounds + ACL

`/etc/hysteria/config.yaml` 末尾追加：

```yaml
outbounds:
  - name: direct
    type: direct
  - name: resi
    type: socks5
    socks5:
      addr: <RESI_HOST>:<RESI_PORT>
      username: <RESI_USER>
      password: <RESI_PASS>
acl:
  inline:
    - direct(suffix:youtube.com)
    # ……其他 YouTube 域名，见下一节
    - resi(suffix:google.com)
    - resi(suffix:googleapis.com)
    # ……与 xray 相同的域名列表
    - resi(suffix:ipinfo.io)
    - direct(all)
```

ACL 从上往下匹配，第一条命中就结束，所以最后一定要有 `direct(all)` 兜底。

```bash
systemctl restart hysteria-server && systemctl is-active hysteria-server
```

### 12.5 验证

在客户端（或者本地起一个 xray 客户端开 socks 端口）分别访问：

```bash
curl -s -x socks5h://127.0.0.1:<LOCAL_PORT> https://ipinfo.io/json   # 应显示住宅 IP，city 为住宅 IP 所在地
curl -s -x socks5h://127.0.0.1:<LOCAL_PORT> https://api.ipify.org    # 应显示 <VPS_IP>
curl -s -o /dev/null -w '%{http_code}\n' -x socks5h://127.0.0.1:<LOCAL_PORT> https://www.google.com  # 200
```

ipinfo 在分流列表里，ipify 不在，两个结果不一样就说明分流生效了：列表里的网站走住宅 IP，其他走 VPS。

> 注意要用 `socks5h://`（域名在代理端解析），用 `socks5://` 时 curl 会先在本地解析成 IP 再发过去，服务端拿不到域名，域名规则就不生效（开了 sniffing 后能补救，见第十四节）。

另外，用 curl 访问 claude.ai、chatgpt.com 返回 403 是正常的，这是 Cloudflare 拦截脚本请求，浏览器里打开没问题。

## 十三、排除 YouTube：视频不要走住宅 IP

### 13.1 为什么

住宅 IP 带宽有限、有的还按流量计费，YouTube 走它既慢又浪费。而 YouTube 属于 Google，如果规则写成"Google 全走住宅"，视频流量会一起被带进去。

### 13.2 为什么不用 geosite:google

`geosite:google` 这个分类里包含 youtube.com、googlevideo.com、ytimg.com 等域名，用它等于把 YouTube 也送进住宅 IP。所以这里改成手写域名列表，只列需要"看起来像美国家庭用户"的域名，YouTube 再单独写一条 direct 规则，**放在 Google 规则前面**。xray 和 Hysteria2 都是按顺序匹配、命中即停：

xray：

```json
{ "type": "field", "ip": ["geoip:private"], "outboundTag": "blocked" },
{
  "type": "field",
  "domain": [
    "domain:youtube.com", "domain:googlevideo.com", "domain:ytimg.com",
    "domain:youtu.be", "domain:ggpht.com", "domain:youtube-nocookie.com"
  ],
  "outboundTag": "direct"
},
{ "...": "然后才是 resi 规则" }
```

Hysteria2：

```yaml
acl:
  inline:
    - direct(suffix:youtube.com)
    - direct(suffix:googlevideo.com)
    - direct(suffix:ytimg.com)
    - direct(suffix:youtu.be)
    - direct(suffix:ggpht.com)
    - direct(suffix:youtube-nocookie.com)
    - resi(suffix:google.com)
    # ...
```

### 13.3 带宽实测

在 VPS 上从 Cloudflare 测速节点下载 20MB：

```bash
# 经住宅 IP
curl -s -o /dev/null -x socks5h://<RESI_USER>:<RESI_PASS>@<RESI_HOST>:<RESI_PORT> \
  -w '%{speed_download} B/s\n' 'https://speed.cloudflare.com/__down?bytes=20000000'
# VPS 直出
curl -s -o /dev/null -w '%{speed_download} B/s\n' 'https://speed.cloudflare.com/__down?bytes=20000000'
```

| 出口 | 下载速度 |
|---|---|
| 住宅 IP | 约 7.4 MB/s（≈59 Mbps） |
| VPS 直出 | 约 65 MB/s（≈520 Mbps） |

住宅 IP 打开 Google 首页约 0.15 s，用来搜索和聊 AI 绰绰有余，但跑视频差了将近 9 倍，所以 YouTube 一定要排除。

### 13.4 验证

```bash
curl -s -o /dev/null -w '%{http_code}\n' -x socks5h://127.0.0.1:<LOCAL_PORT> https://www.youtube.com   # 200
```

也可以在 YouTube 播放器上右键"详细统计信息"，看连接速度是不是跟以前一样。

## 十四、QUIC 导致 Google 定位仍然不对

### 14.1 现象

链式代理配好后，ipinfo.io 显示的是住宅 IP，一切正常，但 Chrome 里 Google 搜 "my location" 还是显示广东。在 `chrome://flags` 里把 **Experimental QUIC protocol** 改成 Disabled 并重启 Chrome 后，定位马上变成美国。

### 14.2 原因

Chrome 访问 Google 默认优先走 QUIC（HTTP/3，UDP 443）。问题出在两处：

1. **分流规则拿不到域名。** Clash TUN 模式 + fake-ip 下，UDP 包到达 VPS 时可能只带 IP、不带域名；服务端没开 sniffing，就不知道这个包是发给 google.com 的，域名规则匹配不上，直接走了 `direct`，出口是 VPS IP，而 Google 的 IP 库把 VPS IP 标成了国内。
2. **住宅 SOCKS5 多半不支持 UDP。** 就算匹配上了，QUIC 也没法稳定地经住宅 IP 出去。

所以 TCP 的 HTTPS 请求走了住宅 IP，QUIC 请求却从 VPS 出去，Google 两边都看到了，就按 VPS IP 定位。ipinfo 不用 QUIC，所以看起来一切正常。

### 14.3 修复思路

不让 Google/AI 的 QUIC 出去，浏览器发现 UDP 443 不通会自动降级到 TCP（HTTPS），而 TCP 已经走住宅 IP。这样客户端什么都不用改，Chrome 的 QUIC 也可以重新打开。

### 14.4 xray

1. 给 VLESS inbound 开 sniffing，从 TLS SNI / HTTP Host / QUIC 握手里还原域名：

```json
"inbounds": [{
  "port": 443,
  "protocol": "vless",
  "settings": { "...": "..." },
  "streamSettings": { "...": "..." },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls", "quic"],
    "routeOnly": true
  }
}]
```

`routeOnly: true` 只用嗅探出的域名做路由匹配，实际连接目标不变，不会因为改写目标地址带来副作用。

2. 加 blackhole 出站，并在 resi 规则**之前**插一条"UDP 443 + 同一份域名 → block"：

```json
{ "tag": "block", "protocol": "blackhole" }
```

```json
"rules": [
  { "type": "field", "ip": ["geoip:private"], "outboundTag": "blocked" },
  { "type": "field", "domain": ["domain:youtube.com", "domain:googlevideo.com", "..."], "outboundTag": "direct" },
  { "type": "field", "network": "udp", "port": "443",
    "domain": ["domain:google.com", "domain:googleapis.com", "...与 resi 相同的列表"],
    "outboundTag": "block" },
  { "type": "field", "domain": ["domain:google.com", "..."], "outboundTag": "resi" },
  { "type": "field", "protocol": ["bittorrent"], "outboundTag": "blocked" }
]
```

最终顺序：私有 IP 屏蔽 → YouTube 直连（TCP/UDP 都直连，YouTube 的 QUIC 不受影响）→ Google/AI 的 UDP 443 屏蔽 → Google/AI 走住宅 → BT 屏蔽 → 其余默认直连。

这里没有用 `geoip:google` 按 IP 屏蔽 UDP，因为 Google 的 IP 段里也有 YouTube 视频服务器，会误伤 YouTube 的 QUIC；按域名 + sniffing 已经够用。

### 14.5 Hysteria2

ACL 支持在规则后面写协议和端口，在 resi 行前面插入 reject：

```yaml
acl:
  inline:
    - direct(suffix:youtube.com)
    # ……YouTube 其他域名
    - reject(suffix:google.com, udp/443)
    - reject(suffix:googleapis.com, udp/443)
    # ……与 resi 相同的列表
    - resi(suffix:google.com)
    - resi(suffix:googleapis.com)
    # ……
    - direct(all)
```

```bash
xray run -test -c /usr/local/etc/xray/config.json
systemctl restart xray hysteria-server
systemctl is-active xray hysteria-server
```

### 14.6 验证

1. 先重跑上面的命令行测试：ipinfo 显示住宅 IP，ipify 显示 `<VPS_IP>`，google.com 返回 200，youtube.com 返回 200。
2. 在 `chrome://flags` 里把 QUIC 改回 Default，重启 Chrome。
3. 打开 Google 搜 "my location"，页面底部应显示美国（住宅 IP 所在地），不再是广东或武汉。
4. 想确认 Google 走的是 TCP：打开开发者工具 → Network，右键表头勾选 Protocol，google.com 的请求应显示 `h2` 而不是 `h3`；YouTube 视频请求仍可以是 `h3`。

## 十五、完整排障顺序

以后遇到“节点测试正常，但网页打不开”时，可以按下面顺序检查。

### 15.1 服务端

```bash
systemctl is-active xray
xray run -test -config /usr/local/etc/xray/config.json
ss -ltnp 'sport = :443'
journalctl -u xray -p err -n 50 --no-pager
```

### 15.2 客户端节点

检查：

- IP 和端口；
- UUID；
- SNI；
- REALITY Public Key；
- Short ID；
- `xtls-rprx-vision`；
- TLS 指纹。

### 15.3 Clash 运行时

不要只看 UI 开关，还要确认：

```text
mode=rule
tun.enable=true
dns-hijack=any:53
目标域名的连接链包含预期代理组
```

### 15.4 DNS

```bash
dig +short www.google.com A
dig +short www.baidu.com A
```

随后做权威 DNS 深度测试，确认没有真实运营商解析器。

### 15.5 目标服务

如果网络、TLS、DNS 和路由均正常，但目标服务仍提示地区不支持，就检查：

- 无痕窗口是否能用；
- 登录前后是否不同；
- Google 搜索页底部如何判断位置；
- 同一服务的所有域名是否使用同一出口；
- 是否需要不同网段、不同 ASN 或住宅/家庭网络出口；
- 在 `chrome://flags` 关闭 QUIC 后重测：若位置随之变正常，说明 UDP 443 绕开了住宅出口，见第十四节。

## 十六、公开发布前的脱敏清单

提交博客前再次搜索：

```bash
rg -n '<真实IP>|<真实UUID>|<真实公钥>|<真实ShortID>|token|password|privateKey' _posts/
```

公开文章中不应包含：

- Xray UUID；
- REALITY 私钥；
- Short ID；
- HomeIP 用户名、密码或订阅地址；
- Clash 订阅 URL；
- 云厂商控制台截图中的实例 ID、账单信息；
- 企业内网域名、DNS 和网段。

REALITY 公钥和服务器 IP 虽然不是传统意义上的私钥，但它们与 UUID、Short ID 组合后就是可使用的节点凭据，因此同样不应完整公开。

## 总结

这次部署最后得到的几个关键经验：

1. Xray 安装成功不等于节点可用，配置自检、systemd、端口和真实客户端缺一不可；
2. REALITY 解决主动探测和 TLS 伪装，但不会隐藏 VPS IP，也无法修复目标服务的 GeoIP 数据；
3. DNS 防泄露不能依靠“多写几个 DNS”，必须按域名类别选择唯一解析路径；
4. Clash Verge Rev 配置失败时可能退回最小配置，UI 仍在不代表 TUN 和 DNS 真正运行；
5. 同一 `/24` 内更换相邻 IP，通常无法改变按网段维护的 GeoIP 结果；
6. 当 Google 对机房 IP 的判断无法纠正时，为 Gemini 单独配置 HomeIP，比反复修改协议和 DNS 更直接；
7. 最可靠的排障方法永远是分层验证：服务端、隧道、DNS、路由、浏览器、目标服务。

自建网络最大的价值不只是“能连上”，而是每一层都能解释、验证、回滚，并且知道问题究竟发生在哪里。
