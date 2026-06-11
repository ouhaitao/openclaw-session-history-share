#!/usr/bin/env node
/**
 * Session History Inject - 安装脚本
 * 
 * 自动完成以下操作：
 * 1. 复制 hook 文件到 ~/.openclaw/hooks/session-history-inject/
 * 2. 在 openclaw.json 中注册 hook
 * 3. 创建 cron 定时任务
 */

import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const HOOK_DIR = path.join(process.env.HOME, '.openclaw', 'hooks', 'session-history-inject');
const CONFIG_FILE = path.join(process.env.HOME, '.openclaw', 'openclaw.json');
const SCRIPT_DIR = path.dirname(new URL(import.meta.url).pathname);
const HOOK_SRC = path.join(SCRIPT_DIR, '..', 'hook');

function log(msg) {
  console.log(`[install] ${msg}`);
}

function error(msg) {
  console.error(`[install] ERROR: ${msg}`);
  process.exit(1);
}

// 1. 复制 hook 文件
function installHook() {
  log('复制 hook 文件...');
  
  if (!fs.existsSync(HOOK_DIR)) {
    fs.mkdirSync(HOOK_DIR, { recursive: true });
  }
  
  const files = ['HOOK.md', 'handler.js'];
  for (const file of files) {
    const src = path.join(HOOK_SRC, file);
    const dst = path.join(HOOK_DIR, file);
    fs.copyFileSync(src, dst);
    log(`  ✓ ${file}`);
  }
}

// 2. 注册 hook 到 openclaw.json
function registerHook() {
  log('注册 hook 到 openclaw.json...');
  
  let config;
  try {
    const raw = fs.readFileSync(CONFIG_FILE, 'utf-8');
    config = JSON.parse(raw);
  } catch (err) {
    error(`无法读取 openclaw.json: ${err.message}`);
  }
  
  // 确保 hooks.internal.enabled
  if (!config.hooks) config.hooks = {};
  if (!config.hooks.internal) config.hooks.internal = { enabled: true };
  if (!config.hooks.internal.entries) config.hooks.internal.entries = {};
  
  config.hooks.internal.entries['session-history-inject'] = { enabled: true };
  
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
  log('  ✓ 已注册 session-history-inject');
}

// 3. 创建 cron 定时任务
function createCronJob() {
  log('创建 cron 定时任务...');
  
  try {
    execSync(`openclaw cron add \
      --name "Session 历史压缩" \
      --cron "30 3 * * *" \
      --tz "Asia/Shanghai" \
      --session isolated \
      --message "读取所有活跃 Session 的 JSONL 尾部，提取 compaction summary 或最近 15 条消息生成摘要，写入 .session_history/<safeKey>/<safeKey>-YYYY-MM-DD.md"`, {
      stdio: 'inherit'
    });
    log('  ✓ Cron 任务已创建');
  } catch (err) {
    log(`  ⚠ Cron 创建失败，请手动创建`);
  }
}

// 主流程
try {
  installHook();
  registerHook();
  createCronJob();
  
  log('');
  log('安装完成！重启 OpenClaw 生效：');
  log('  openclaw gateway restart');
} catch (err) {
  error(`安装失败: ${err.message}`);
}
