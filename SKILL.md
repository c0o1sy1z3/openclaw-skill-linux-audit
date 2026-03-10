---
name: linux-openclaw-audit
description: Execute a comprehensive, 8-phase security audit on Linux servers running OpenClaw. Covers system profiling, network exposure, SSH defense, shadow accounts/privileges, vulnerabilities, container escapes, rootkits, and OpenClaw health. Use when users ask for a security check, audit, or host hardening status.
---

# Linux & OpenClaw Security Audit

This skill provides a fully automated, read-only security auditing script for Linux servers running OpenClaw. It evaluates the host against enterprise-grade hardening standards (e.g., PAM, sysctl, chattr, limits.conf) and OpenClaw's own security posture.

## Quick Start

To run the full audit and generate the report:

1. Execute the bundled script:
   ```bash
   bash scripts/audit.sh
   ```
2. The script will output a structured report with [CRITICAL], [WARNING], and [PASS] tags.
3. Review the findings and present the generated "One-click prescriptions" (remediation commands) to the user for any critical or warning items.

## Audit Phases

1. **Phase 0: System Profiling**: Identifies Cloud Provider (ASN/DMI), OS/Kernel version, Uptime, Hardware load, and OpenClaw instance status.
2. **Phase 1: Network & Exposure**: Checks UFW status, open listening ports, and TCP/IP sysctl parameters (SYN cookies, rp_filter).
3. **Phase 2: SSH Defense**: Audits `sshd_config` (Root/Password auth), `auth.log` for brute-force, PAM lockouts, and `TMOUT` idle timeouts.
4. **Phase 3: Shadow Accounts & Privileges**: Scans `/etc/passwd` for UID 0, high-risk SUID binaries, `chattr` locks on core files, and `gcc` permissions.
5. **Phase 4: Vulnerabilities & Zombies**: Checks for apt/yum pending security updates and zombie processes.
6. **Phase 5: Container & Resource Constraints**: Audits Docker privileged containers/ports and `/etc/security/limits.conf` (nproc/nofile) against fork bombs.
7. **Phase 6: Rootkit Scan**: Wraps `rkhunter` or `chkrootkit` (if installed) filtering known OpenClaw false positives.
8. **Phase 7: OpenClaw Health**: Runs `openclaw security audit --deep` and evaluates sandbox constraints.

## Execution & Remediation Workflow

When you trigger the audit script, strictly follow this workflow:

0. **Async Execution (CRITICAL)**: Because `rkhunter` can take several minutes, you MUST use the `exec` tool with `background: true` (or rely on `yieldMs`) to run the script `bash scripts/audit.sh`. Then, repeatedly use the `process` tool with `action: poll` to check the `sessionId` until the script completes. Do NOT run it synchronously, or the OpenClaw request will time out.
1. **Pre-flight Check**: If the script exits with `[PRE-FLIGHT FAILED]`, halt the audit process. Inform the user in chat which tools are missing (e.g., `ufw`, `rkhunter`), provide the installation commands, and ask for permission to install them. Once the user approves and the tools are installed, re-run the audit script. Do not generate any Markdown report if the pre-flight check fails.
1. **Detailed Local Markdown Report (CRITICAL & MANDATORY)**: After a successful run, before you reply in chat, you MUST use the `write` tool to save a highly detailed, comprehensive Markdown report to the current workspace (e.g., `audit_report_YYYYMMDD_HHMMSS.md`). This file must NOT omit any details. Include the full System Profile, all Audit Findings, detailed Rootkit Analysis, and full Remediation Prescriptions with Side Effects. DO NOT skip this step under any circumstances.
2. **Chat Summary**: Present a summarized version of the [CRITICAL], [WARNING], and [PASS] findings in the chat.
3. **Rootkit Analysis (Chat & Doc)**: Evaluate if any suspicious files are false positives or genuine threats.
4. **One-click Prescription (Chat & Doc)**: Provide the exact commands needed to fix the [CRITICAL] and [WARNING] findings.
5. **CRITICAL REQUIREMENT (Side Effects)**: For every suggested fix in the prescription, you MUST attach a "⚠️ 修复副作用 (Side Effects)" explanation.
6. **File Path Reference**: At the very end of your chat message, explicitly state the absolute path and filename of the detailed Markdown report you generated.
7. Wait for the user's approval before executing any remediation commands.
