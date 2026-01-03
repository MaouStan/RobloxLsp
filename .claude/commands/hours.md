# /hours — สรุปชั่วโมงทำงานวันนี้

ดึงเวลาเริ่ม-จบ session จาก retrospectives + commits

## Step 0: Timestamp (REQUIRED)
```bash
date "+🕐 %H:%M (%A %d %B %Y)"
```

## Usage

```
/hours           # วันนี้
/hours yesterday # เมื่อวาน
/hours 2025-12-11  # วันที่ระบุ
```

## Action

Use context-finder to:

1. **Get retro filenames** (หลัก)
   ```bash
   # List retro files for the day
   ls ψ/memory/retrospectives/YYYY-MM/DD/*.md

   # Extract time from filename (e.g., 07.00-xxx.md = 07:00)
   # First file = start time
   # Last file = end time
   ```

2. **Read Duration from each retro** (ถ้ามี)
   ```bash
   # For each file, read first 10 lines to get:
   # - Duration: ~X hours (or Start Time → End Time)
   head -10 [file] | grep -E "Duration|Start Time|End Time"
   ```

3. **Get commit times** (reference)
   ```bash
   git log --since="$DATE 00:00" --until="$DATE 23:59" --format="%ai" --reverse | head -1
   git log --since="$DATE 00:00" --until="$DATE 23:59" --format="%ai" | head -1
   git log --since="$DATE 00:00" --until="$DATE 23:59" --format="%h" | wc -l
   ```

4. **Filter overnight** — ถ้า retro มี "overnight" ใน Duration → mark 🌙

## Output Format

```markdown
## ⏱️ /hours — [DATE]

### Timeline
| | Time | Source |
|-|------|--------|
| 🌅 Start | 06:37 | first commit |
| 🌆 End | 18:55 | last retro (18.55-xxx.md) |
| ⏱️ Duration | ~12 hours | |

### Stats
- Commits: 35
- Retrospectives: 13

### Sessions
| Time | Focus | Duration |
|------|-------|----------|
| 🌙 07:00 | overnight agents concepts | ~9h (22:00→07:00) |
| 09:30 | content commands identity | ~2h |
| 10:00 | siit workshop | ~1h |
| ... | ... | ... |

### Reference (commits)
- First commit: 06:37
- Last commit: 19:01

---
💤 พักผ่อนด้วยนะ!
```

## Rules

1. **Start time** = commit แรกของวัน (เวลาเริ่มทำงานจริง)
2. **End time** = retro สุดท้ายของวัน (เวลาสรุปงาน)
3. **Duration** = End - Start
4. **🌙** = overnight session (ถ้า Duration มี "overnight" หรือ "→" ข้ามวัน)
5. **Sessions** = จาก retro filenames + Duration ใน file

## Notes

- Commit แรก = เริ่มทำงาน (เพราะ retro เขียนทีหลัง)
- Retro สุดท้าย = จบงาน (เพราะเป็นการสรุป)
- ถ้าไม่มี retro → ใช้ commit สุดท้ายแทน
