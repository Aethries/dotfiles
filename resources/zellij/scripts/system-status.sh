#!/usr/bin/env bash

set -euo pipefail

read_cpu_sample() {
    local _label user nice system idle iowait irq softirq steal _guest _guest_nice
    read -r _label user nice system idle iowait irq softirq steal _guest _guest_nice < /proc/stat
    printf '%s %s\n' \
        "$((user + nice + system + idle + iowait + irq + softirq + steal))" \
        "$((idle + iowait))"
}

read_network_sample() {
    awk '
        NR > 2 {
            gsub(/:/, " ")
            if ($1 != "lo") {
                rx += $2
                tx += $10
            }
        }
        END { printf "%.0f %.0f\n", rx, tx }
    ' /proc/net/dev
}

format_rate() {
    awk -v bytes="$1" 'BEGIN {
        if (bytes >= 1048576) printf "%.1fM", bytes / 1048576
        else if (bytes >= 1024) printf "%.0fK", bytes / 1024
        else printf "%.0fB", bytes
    }'
}

read -r total_before idle_before < <(read_cpu_sample)
read -r rx_before tx_before < <(read_network_sample)
sample_started=$(date +%s%N)
sleep 0.2
read -r total_after idle_after < <(read_cpu_sample)
read -r rx_after tx_after < <(read_network_sample)
sample_finished=$(date +%s%N)

total_delta=$((total_after - total_before))
idle_delta=$((idle_after - idle_before))
cpu_percent=0
if ((total_delta > 0)); then
    cpu_percent=$((100 * (total_delta - idle_delta) / total_delta))
fi

memory_percent=$(awk '
    /^MemTotal:/ { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END { printf "%d", (total - available) * 100 / total }
' /proc/meminfo)

sample_duration=$((sample_finished - sample_started))
if ((sample_duration > 0)); then
    rx_rate=$(((rx_after - rx_before) * 1000000000 / sample_duration))
    tx_rate=$(((tx_after - tx_before) * 1000000000 / sample_duration))
else
    rx_rate=0
    tx_rate=0
fi

disk_percent=$(df -Pk / | awk 'NR == 2 { print $5 }')
disk_percent=${disk_percent%%%}

printf '󰍛%s │ %s%% %s%% 󰓅↓%s↑%s 󰋊%s%%' \
    "$(hostname -s)" \
    "$cpu_percent" \
    "$memory_percent" \
    "$(format_rate "$rx_rate")" \
    "$(format_rate "$tx_rate")" \
    "$disk_percent"
