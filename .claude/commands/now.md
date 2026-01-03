---
description: Show what we're doing now - session awareness
fear: confusion about current state
---

# /now - What Are We Doing?

AI buddy confirms current session state with human.

## Usage

```
/now
```

## Implementation

**AI reconstructs session from memory** — no file reading needed.

Output format:

```markdown
## 🕐 This Session

| Time | Duration | Topic |
|------|----------|-------|
| HH:MM | ~Xm | First topic |
| HH:MM | ~Xm | ↩️ Second topic (jumped: reason) |
| HH:MM | ongoing | **Now**: Current topic |

**🔍 Noticed**:
- [Pattern - energy/mode]
- [Pattern - why jumps happened]

**📍 Status**:
- 🔥/🟡/🔴 Energy: [level]
- ⚠️ Loose ends: [unfinished]

**💭 My Read**: [1-2 sentences]

**💡 Learned**:
- [Insight 1]
- [Insight 2]

---
**Persist?** (y/n)
```

## Key Principles

| Principle | How |
|-----------|-----|
| **AI memory only** | No stale file data |
| **Buddy, not robot** | Natural observations |
| **Timeline + Interpretation** | Facts then patterns |
| **Persist optional** | User decides |

## Why This Command

| Fear | Solution |
|------|----------|
| "What are we doing?" | Timeline |
| "Why did we jump?" | Noticed |
| "What did we learn?" | Learned |
| "Am I scattered?" | My Read |

## Example

```markdown
## 🕐 This Session

| Time | Duration | Topic |
|------|----------|-------|
| 09:06 | ~4m | /trace insight origins |
| 09:10 | ~7m | ↩️ Lab project setup (jumped: "can we make project?") |
| 09:17 | ~1m | ↩️ nnn Issue #63 (jumped: formalize plan) |
| 09:18 | ~4m | ↩️ Vision discussion (jumped: "lets talk vision!") |
| 09:22 | ongoing | **Now**: /now command |

**🔍 Noticed**:
- Building mode all session
- Jumps = new ideas sparked, not escape

**📍 Status**:
- 🔥 Energy: High
- ⚠️ Loose ends: #63, #64

**💭 My Read**: Discovery mode. Ideas flow, implementation รอได้.

**💡 Learned**:
- Documentation = Fear Management
- AI = buddy, not robot

---
**Persist?** (y/n)
```
