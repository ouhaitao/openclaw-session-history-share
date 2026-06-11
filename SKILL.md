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
  --message "读取所有活跃 Session 的 JSONL 尾部，向前查找最近 compaction 事件提取 summary，或提取最近 200 条消息生成简要摘要，写入 .session_history/<safeKey>/<safeKey>-YYYY-MM-DD.md（safeKey=冒号替换下划线，文件内容纯摘要正文，无 metadata，每个 sessionKey 保留最近 3 个存档）"
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
