# Session History Inject

跨 Session 对话历史自动注入方案。在每日重置后，自动将旧 Session 的压缩摘要注入新 Session 上下文。

## 原理

```
3:30 AM → Cron 读取活跃 Session 的 JSONL
        → 提取 compaction summary 或最近消息摘要
        → 存档到 .session_history/<safeKey>/<safeKey>-YYYY-MM-DD.md

4:00 AM → OpenClaw 定时重置 Session

新 Session 每轮 → agent:bootstrap hook 读取最新存档
                → 注入到 bootstrapFiles (BOOTSTRAP.md)
                → 摘要拼入 prompt
```

## 安装

```bash
# 自动安装（创建 hook + 配置 cron）
node ~/.openclaw/workspace/skills/session-history-inject/scripts/install.sh

# clawhub
openclaw skills install session-history-share

# 或手动安装
# 1. 复制 hook 目录到 ~/.openclaw/hooks/session-history-inject/
# 2. 在 openclaw.json 注册 hook
# 3. 创建 cron 定时任务
```

## 配置

### Hook 注册（openclaw.json）
```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "session-history-inject": {
          "enabled": true
        }
      }
    }
  }
}
```

### 定时任务
```bash
openclaw cron add \
  --name "定时压缩活跃会话" \
  --cron "30 3 * * *" \
  --tz "Asia/Shanghai" \
  --session isolated \
  --message "执行以下步骤压缩所有活跃会话：\n\n1. 使用 sessions_list 获取所有活跃 session（排除 cron 和 subagent）\n2. 对每个 session 的 transcriptPath（JSONL 文件），执行以下步骤：\n   a. 使用 read 读取 JSONL 文件尾部（用 limit 从 offset 读取，不要读完整文件）\n   b. 从最后一条消息向前查找，找到最近的 compaction 事件（type=compaction）\n   c. 如果找到 compaction：提取 compaction.summary 字段的纯文本值\n   d. 如果没找到 compaction：提取最近 200 条 user/assistant 消息，生成简要摘要\n   e. 将摘要内容写入 .session_history/<safeSessionKey>/<safeSessionKey>-<YYYY-MM-DD>.md\n      - safeSessionKey 是把 sessionKey 中的冒号替换为下划线\n   f. 生成的摘要在**不丢失关键内容**的情况下尽可能的**简短**\n1. **文件内容只包含摘要正文纯文本，不要写任何 metadata header（不要 Session Key、Date、分隔线、标题等）**\n2. 每个 sessionKey 只保留最近 3 个存档文件，删除旧的\n3. 完成后回复 NO_REPLY"
```

## 查看日志

```bash
openclaw logs | grep "session-history"
```

## 卸载

```bash
node ~/.openclaw/workspace/skills/session-history-inject/scripts/uninstall.sh
```

## 文件结构

```
skills/session-history-inject/
├── SKILL.md
├── scripts/
│   ├── install.sh
│   └── uninstall.sh
└── hook/
    ├── HOOK.md
    └── handler.js
```
