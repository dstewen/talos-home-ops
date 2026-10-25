#!/usr/bin/env bash

# Check if nodes are provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <node-1-ip-or-hostname> [node-2-ip-or-hostname] ..."
    exit 1
fi

printf "%-25s %s\n" "NODE" "UPTIME"
printf "%-25s %s\n" "-------------------------" "-------------------------"

for node in "$@"; do
    # Fetch raw uptime from the node using talosctl
    raw_uptime=$(talosctl read /proc/uptime --nodes "$node" 2>/dev/null | awk '{print $1}')
    
    if [ -z "$raw_uptime" ]; then
        printf "%-25s %s\n" "$node" "[Error: Unable to reach node]"
        continue
    fi
    
    # Convert float seconds to an integer
    seconds=${raw_uptime%.*}
    
    # Calculate intervals
    days=$(( seconds / 86400 ))
    hours=$(( (seconds % 86400) / 3600 ))
    minutes=$(( (seconds % 3600) / 60 ))
    secs=$(( seconds % 60 ))
    
    # Format output
    uptime_str=""
    [ "$days" -gt 0 ] && uptime_str="${days}d "
    [ "$hours" -gt 0 ] || [ "$days" -gt 0 ] && uptime_str="${uptime_str}${hours}h "
    [ "$minutes" -gt 0 ] || [ "$hours" -gt 0 ] || [ "$days" -gt 0 ] && uptime_str="${uptime_str}${minutes}m "
    uptime_str="${uptime_str}${secs}s"
    
    printf "%-25s %s\n" "$node" "$uptime_str"
done
