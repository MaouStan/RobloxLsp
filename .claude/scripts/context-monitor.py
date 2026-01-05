#!/usr/bin/env python3
"""
Claude Code Context Monitor - Oh My Posh Atomic Theme Style
Real-time context usage monitoring with visual indicators and session analytics
"""

import json
import sys
import os
import re
import subprocess
import socket
from datetime import datetime

def parse_context_from_transcript(transcript_path):
    """Parse context usage from transcript file."""
    if not transcript_path or not os.path.exists(transcript_path):
        return None
    
    try:
        with open(transcript_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
        
        # Check last 15 lines for context information
        recent_lines = lines[-15:] if len(lines) > 15 else lines
        
        for line in reversed(recent_lines):
            try:
                data = json.loads(line.strip())
                
                # Method 1: Parse usage tokens from assistant messages
                if data.get('type') == 'assistant':
                    message = data.get('message', {})
                    usage = message.get('usage', {})
                    
                    if usage:
                        input_tokens = usage.get('input_tokens', 0)
                        cache_read = usage.get('cache_read_input_tokens', 0)
                        cache_creation = usage.get('cache_creation_input_tokens', 0)
                        
                        # Estimate context usage (assume 200k context for Claude Sonnet)
                        total_tokens = input_tokens + cache_read + cache_creation
                        if total_tokens > 0:
                            percent_used = min(100, (total_tokens / 200000) * 100)
                            return {
                                'percent': percent_used,
                                'tokens': total_tokens,
                                'method': 'usage'
                            }
                
                # Method 2: Parse system context warnings
                elif data.get('type') == 'system_message':
                    content = data.get('content', '')
                    
                    # "Context left until auto-compact: X%"
                    match = re.search(r'Context left until auto-compact: (\d+)%', content)
                    if match:
                        percent_left = int(match.group(1))
                        return {
                            'percent': 100 - percent_left,
                            'warning': 'auto-compact',
                            'method': 'system'
                        }
                    
                    # "Context low (X% remaining)"
                    match = re.search(r'Context low \((\d+)% remaining\)', content)
                    if match:
                        percent_left = int(match.group(1))
                        return {
                            'percent': 100 - percent_left,
                            'warning': 'low',
                            'method': 'system'
                        }
            
            except (json.JSONDecodeError, KeyError, ValueError):
                continue
        
        return None
        
    except (FileNotFoundError, PermissionError):
        return None

def get_context_display(context_info):
    """Generate context display with visual indicators - atomic theme style."""
    if not context_info:
        return "\033[38;5;117m🔵 ???\033[0m"

    percent = context_info.get('percent', 0)
    warning = context_info.get('warning')

    # Color and icon based on usage level - atomic palette
    if percent >= 95:
        icon, color = "🚨", "\033[38;5;203m"  # Bright red
        alert = "CRIT"
    elif percent >= 90:
        icon, color = "🔴", "\033[38;5;196m"    # Red
        alert = "HIGH"
    elif percent >= 75:
        icon, color = "🟠", "\033[38;5;215m"   # Orange
        alert = ""
    elif percent >= 50:
        icon, color = "🟡", "\033[38;5;226m"   # Yellow
        alert = ""
    else:
        icon, color = "🟢", "\033[38;5;48m"   # Green
        alert = ""

    # Create progress bar
    segments = 8
    filled = int((percent / 100) * segments)
    bar = "█" * filled + "▁" * (segments - filled)

    # Special warnings
    if warning == 'auto-compact':
        alert = "AUTO-COMPACT!"
    elif warning == 'low':
        alert = "LOW!"

    reset = "\033[0m"
    alert_str = f" {alert}" if alert else ""

    return f"{icon}{color}{bar}{reset} {percent:.0f}%{alert_str}"

def get_directory_display(workspace_data):
    """Get directory display name."""
    current_dir = workspace_data.get('current_dir', '')
    project_dir = workspace_data.get('project_dir', '')
    
    if current_dir and project_dir:
        if current_dir.startswith(project_dir):
            rel_path = current_dir[len(project_dir):].lstrip('/')
            return rel_path or os.path.basename(project_dir)
        else:
            return os.path.basename(current_dir)
    elif project_dir:
        return os.path.basename(project_dir)
    elif current_dir:
        return os.path.basename(current_dir)
    else:
        return "unknown"

def get_session_metrics(cost_data):
    """Get session metrics display."""
    if not cost_data:
        return ""
    
    metrics = []
    
    # Cost
    cost_usd = cost_data.get('total_cost_usd', 0)
    if cost_usd > 0:
        if cost_usd >= 0.10:
            cost_color = "\033[31m"  # Red for expensive
        elif cost_usd >= 0.05:
            cost_color = "\033[33m"  # Yellow for moderate
        else:
            cost_color = "\033[32m"  # Green for cheap
        
        cost_str = f"{cost_usd*100:.0f}¢" if cost_usd < 0.01 else f"${cost_usd:.3f}"
        metrics.append(f"{cost_color}💰 {cost_str}\033[0m")
    
    # Duration
    duration_ms = cost_data.get('total_duration_ms', 0)
    if duration_ms > 0:
        minutes = duration_ms / 60000
        if minutes >= 30:
            duration_color = "\033[33m"  # Yellow for long sessions
        else:
            duration_color = "\033[32m"  # Green
        
        if minutes < 1:
            duration_str = f"{duration_ms//1000}s"
        else:
            duration_str = f"{minutes:.0f}m"
        
        metrics.append(f"{duration_color}⏱ {duration_str}\033[0m")
    
    # Lines changed
    lines_added = cost_data.get('total_lines_added', 0)
    lines_removed = cost_data.get('total_lines_removed', 0)
    if lines_added > 0 or lines_removed > 0:
        net_lines = lines_added - lines_removed
        
        if net_lines > 0:
            lines_color = "\033[32m"  # Green for additions
        elif net_lines < 0:
            lines_color = "\033[31m"  # Red for deletions
        else:
            lines_color = "\033[33m"  # Yellow for neutral
        
        sign = "+" if net_lines >= 0 else ""
        metrics.append(f"{lines_color}📝 {sign}{net_lines}\033[0m")
    
    return f" \033[90m|\033[0m {' '.join(metrics)}" if metrics else ""

def get_agent_display(data):
    """Get agent/user display from Claude Code data - Oh My Posh atomic style."""
    # Get hostname
    hostname = socket.gethostname().split('.')[0]

    # Check if running as agent/subagent
    agent_mode = data.get('agent_mode', False)
    agent_name = data.get('agent_name', '')
    parent_agent = data.get('parent_agent', '')

    # Check for user info
    user = data.get('user', {}).get('username', '')
    user_display = data.get('user', {}).get('display_name', '')

    # Default to current user if not specified
    import getpass
    current_user = getpass.getuser()

    # Atomic theme uses bright blue for shell/terminal
    shell_color = "\033[38;5;39m"  # Bright blue (matches atomic #0077c2)
    reset = "\033[0m"

    if agent_name:
        # Subagent is active - show agent chain (magenta for agents)
        if parent_agent:
            return f"\033[38;5;207m{agent_name}{reset}\033[90m@\033[0m\033[38;5;117m{parent_agent}{reset}"
        else:
            return f"\033[38;5;207m{agent_name}{reset}\033[90m@\033[0m\033[38;5;117m{hostname}{reset}"
    elif agent_mode:
        return f"\033[38;5;207magent{reset}\033[90m@\033[0m\033[38;5;117m{hostname}{reset}"
    else:
        # Main Claude - show user@host like oh-my-posh atomic theme
        display_user = user_display or user or current_user
        # Atomic theme: user in blue, @ in dim, host in bright cyan
        return f"{shell_color}{display_user}{reset}\033[90m@\033[0m\033[38;5;117m{hostname}{reset}"

def get_git_branch_display(workspace_data):
    """Get git branch display with status indicators."""
    current_dir = workspace_data.get('current_dir', '')
    project_dir = workspace_data.get('project_dir', '')
    work_dir = project_dir if project_dir else current_dir

    if not work_dir or not os.path.exists(work_dir):
        return ""

    git_dir = os.path.join(work_dir, '.git')
    if not os.path.exists(git_dir):
        return ""

    try:
        # Get branch name
        result = subprocess.run(
            ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
            cwd=work_dir,
            capture_output=True,
            text=True,
            timeout=1
        )
        branch = result.stdout.strip() if result.returncode == 0 else ""

        if not branch or branch == 'HEAD':
            return ""

        # Check for detached HEAD
        if branch == 'HEAD':
            # Get commit short hash
            result = subprocess.run(
                ['git', 'rev-parse', '--short', 'HEAD'],
                cwd=work_dir,
                capture_output=True,
                text=True,
                timeout=1
            )
            branch = result.stdout.strip() if result.returncode == 0 else "detached"

        # Check for changes (staged + unstaged)
        result = subprocess.run(
            ['git', 'status', '--porcelain'],
            cwd=work_dir,
            capture_output=True,
            text=True,
            timeout=1
        )

        status_icon = ""
        if result.returncode == 0 and result.stdout.strip():
            lines = result.stdout.strip().split('\n')
            staged = any(line.startswith(('M ', 'A ', 'D ', 'R ', 'C ')) for line in lines)
            unstaged = any(line[:2] in (' M', ' A', ' D', ' R', ' C', 'MM', 'AA', 'DD') for line in lines)
            untracked = any(line.startswith('??') for line in lines)

            if staged and unstaged:
                status_icon = "\033[33m✖\033[0m"  # Both staged and unstaged
            elif staged:
                status_icon = "\033[32m●\033[0m"   # Staged only
            elif unstaged:
                status_icon = "\033[31m✚\033[0m"   # Unstaged only
            elif untracked:
                status_icon = "\033[36m?\033[0m"    # Untracked only

        # Color coding for branch states - atomic theme palette
        # Atomic theme uses #FFFB38 (bright yellow) background for git
        if branch == 'main' or branch == 'master':
            branch_color = "\033[38;5;39m"  # Bright blue (atomic style)
        elif branch.startswith('feature/'):
            branch_color = "\033[38;5;213m"  # Light purple (atomic #C792EA)
        elif branch.startswith('fix/') or branch.startswith('bugfix/'):
            branch_color = "\033[38;5;215m"  # Orange
        elif branch.startswith('hotfix/'):
            branch_color = "\033[38;5;203m"  # Red
        else:
            branch_color = "\033[38;5;226m"  # Bright yellow (atomic git color)

        # Shorten long branch names
        display_branch = branch
        if len(branch) > 15:
            parts = branch.split('/')
            if len(parts) > 1:
                display_branch = f"{parts[0]}/{parts[-1][:10]}"
            else:
                display_branch = branch[:12] + ".."

        status_suffix = f" {status_icon}" if status_icon else ""
        # No separator here - added in main
        return f"{branch_color}🌿 {display_branch}\033[0m{status_suffix}"

    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        return ""

def get_time_display():
    """Get current time display - atomic theme style."""
    now = datetime.now()
    # Atomic theme uses bright cyan/blue for time segment (#40c4ff)
    time_str = now.strftime("%H:%M")
    return f"\033[38;5;81m🕐 {time_str}\033[0m"

def main():
    # Fix Windows encoding issues
    if sys.platform == 'win32':
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

    try:
        # Read JSON input from Claude Code
        data = json.load(sys.stdin)

        # Extract information
        model_name = data.get('model', {}).get('display_name', 'Claude')
        workspace = data.get('workspace', {})
        transcript_path = data.get('transcript_path', '')
        cost_data = data.get('cost', {})

        # Parse context usage
        context_info = parse_context_from_transcript(transcript_path)

        # Build status components
        agent_display = get_agent_display(data)
        context_display = get_context_display(context_info)
        directory = get_directory_display(workspace)
        session_metrics = get_session_metrics(cost_data)
        git_display = get_git_branch_display(workspace)
        time_display = get_time_display()

        # Model display with context-aware coloring - atomic theme palette
        if context_info:
            percent = context_info.get('percent', 0)
            if percent >= 90:
                model_color = "\033[38;5;203m"  # Red
            elif percent >= 75:
                model_color = "\033[38;5;226m"  # Yellow
            else:
                model_color = "\033[38;5;48m"  # Green
        else:
            model_color = "\033[38;5;255m"  # White

        # Combine all components - oh-my-posh atomic theme style
        # Format: dir branch context time (no user@host)
        # Using powerline separators like atomic theme
        parts = [
            f"\033[38;5;230m{directory}\033[0m",  # Bright orange-white for path
        ]

        # Add git branch if available
        if git_display.strip():
            parts.append(f"\033[90m\ue0b0\033[0m {git_display.strip()}")

        # Add remaining components
        parts.extend([
            f"\033[90m\ue0b0\033[0m {model_color}🤖 {model_name}\033[0m",
            f"\033[90m\ue0b0\033[0m 🧠 {context_display}",
            f"\033[90m\ue0b0\033[0m {time_display}"
        ])

        # Filter out empty parts
        status_line = " ".join([p for p in parts if p])

        print(status_line)
        
    except Exception as e:
        # Fallback display on any error
        print(f"\033[94m[Claude]\033[0m \033[93m📁 {os.path.basename(os.getcwd())}\033[0m 🧠 \033[31m[Error: {str(e)[:20]}]\033[0m")

if __name__ == "__main__":
    main()