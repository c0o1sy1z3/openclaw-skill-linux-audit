# 🛡️ Linux & OpenClaw 企业级自动化安全审计 (linux-openclaw-audit)

[![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-Skill-blue.svg)](https://github.com/openclaw/openclaw)
[![Security](https://img.shields.io/badge/Security-Audit-red.svg)]()

专为 OpenClaw 打造的底层系统环境与进程级自动化安全体检技能 (Skill)。

本技能不仅仅是跑跑脚本，它能够在 OpenClaw 智能 Agent 的调度下，完成“**环境检测 -> 底层扫描 -> AI 二次确诊 -> 出具完整报告与修复处方**”的企业级闭环体验。

**注意：下载到对应目录后删除README.md**

## ✨ 核心特性 (Features)

本技能将底层服务器体检划分为 8 大阶段（Phase 0 ~ Phase 7）：

1. **基础资产画像**: 自动识别云厂商 (ASN/DMI)、内核版本、系统负载与 OpenClaw 运行状态。
2. **网络与暴露面**: 检查防火墙状态，审计内核级防 DDoS 参数 (TCP SYN Cookies, RP Filter)。
3. **SSH 登录防线**: 审查 Root 直连、密码爆破风险与 TMOUT 终端防挂机策略。
4. **影子账户与越权**: 盘点 `UID=0` 账户，揪出高危的 `GCC` 编译器越权，检查 `/etc/passwd` 等命脉文件的底层不可篡改锁 (`chattr`)。
5. **漏洞与僵尸进程**: 排查僵死进程。
6. **容器与资源配额**: 扫荡 Docker 特权容器逃逸风险，审计 `limits.conf` 防 Fork 炸弹配额 (nproc/nofile)。
7. **Rootkit 深度查杀**: 联动 `rkhunter` 进行全盘木马与后门扫描，并由 OpenClaw 的 LLM 进行假阳性 (False Positive) 二次确诊。
8. **处方与副作用警告**: 针对每一项红灯警告，一键生成复制即用的 Bash 修复指令，并**强制附带副作用警告 (Side Effects)**，防止无脑修补导致业务瘫痪。

## 📦 安装与使用 (Installation & Usage)

### 安装
1. 确保你的机器上已运行 OpenClaw 环境。
2. 下载本仓库的 `linux-openclaw-audit.skill` 包，或者直接让你的 OpenClaw Agent 读取本目录。

### 触发方式
在你的客户端（如飞书、Discord、Terminal）直接对你的 OpenClaw 说：
- *"给我做个服务器全栈安全体检"*
- *"运行 linux-openclaw-audit"*

### 依赖组件
体检脚本 (`scripts/audit.sh`) 会自动进行 Pre-flight 检查。如果你的系统缺失以下组件，Agent 会主动向你申请安装权限：
- `ufw` (防火墙状态探测)
- `rkhunter` (底层 Rootkit 与木马扫描)

## 📄 报告生成
扫描完成后，技能不仅会在聊天窗口给你发送一份精简的核心速览，还会强制在你的 Agent Workspace 目录下生成一份**一字不落的满血版 Markdown 深度体检报告**（包含所有的原始日志与详尽的修复处方），极大地满足企业资产归档需求。

---
*Powered by OpenClaw Agent*
