---
description: Smart topic switching with multi-track system
allowed-tools:
  - Bash
---

# /jump - Multi-Track Topic Management

Switch between work tracks with time-decay visibility.

## Usage

```
/jump              # Show all tracks (INDEX.md)
/jump [topic]      # Create new track + update focus
/jump back         # Pop from stack (return to previous)
/jump list         # Alias to no-args
```

## Implementation

```bash
bash .claude/scripts/jump.sh $ARGUMENTS
```

Display output directly, no additions needed.

## Time Decay Status

| Status | Age | Meaning |
|--------|-----|---------|
| Hot | <1h | Active now |
| Warm | <24h | Today's work |
| Cooling | 1-7d | Needs attention |
| Cold | >7d | Forgotten? |
| Dormant | >30d | Archive candidate |

## Track Files

Location: `psi/inbox/tracks/YYMMDDHHMM-topic.md`

Created with template containing:
- Goal
- Current State
- Next Action
- Context

## Arguments
ARGUMENTS: $ARGUMENTS
