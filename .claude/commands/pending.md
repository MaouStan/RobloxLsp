---
description: Show pending tasks (tracks + GitHub issues) with priority
allowed-tools:
  - Read
  - Glob
  - Grep
  - Task
---

# /pending - What's Pending

Show pending work from tracks + GitHub issues with priority.

## Usage
```
/pending
```

## Steps

### Step 0: Timestamp (REQUIRED)
```bash
date "+🕐 %H:%M (%A %d %B %Y)"
```

### Step 1: Read Tracks

```
Read ψ/inbox/tracks/INDEX.md
```

This shows all active tracks with their heat status:
- 🔥 Hot (<1h) - Active now
- 🟢 Warm (<24h) - Recent
- 🟡 Cooling (1-7d) - Need attention
- 🔴 Cold (>7d) - Forgotten
- ⚪ Dormant (>30d) - Archive candidate

### Step 2: Scan context for pending items

Use Task tool with:
- `subagent_type`: `context-finder`
- `model`: `haiku`
- `prompt`:
```
Find pending tasks from:
1. Open GitHub issues: gh issue list --state open --limit 10
2. Recent TODOs in code: grep -r "TODO\|FIXME" --include="*.ts" --include="*.md" . | head -10
3. Uncommitted work: git status --short

Return compact list only.
```

### Step 3: Combine & Prioritize

Output format:

```
## /pending - งานค้าง

### 🔥 Active Tracks
| Track | Status | Next Action |
|-------|--------|-------------|
| [name] | [heat] | [from track file] |

### 🔴 URGENT (today/blocking)
- [ ] Task description — source

### 🟠 SOON (this week)
- [ ] Task description — source

### 🟡 LATER (backlog)
- [ ] Task description — source

---
**Sources**: Tracks, GitHub Issues, Context
```

## Priority Rules

| Priority | Criteria |
|----------|----------|
| 🔥 Active | Hot/Warm tracks from INDEX |
| 🔴 URGENT | Has deadline today, blocking other work |
| 🟠 SOON | Cooling tracks, active GitHub issue |
| 🟡 LATER | TODO in code, someday/maybe |

## Note

ถ้าไม่มี tracks → แสดงแค่ context + GitHub issues
