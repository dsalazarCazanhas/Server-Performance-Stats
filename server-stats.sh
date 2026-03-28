#! /usr/bin/bash

# ─── Colors ─────────────────────────────────────────────────────────────────
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ─── Table borders ───────────────────────────────────────────────────────────
# Visual width: 61 chars  (║ + sp + 19 + sp + ║ + sp + 35 + sp + ║)
TOP_BORDER="╔═══════════════════════════════════════════════════════════╗"
HDR_SPLIT="╠═════════════════════╦═════════════════════════════════════╣"
ROW_SEP="╠═════════════════════╬═════════════════════════════════════╣"
BTM_BORDER="╚═════════════════════╩═════════════════════════════════════╝"

# Process table borders (PID:6 | COMMAND:26 | CPU%:8 | MEM%:8) — also 61-wide
PROC_HDR_SEP="╠════════╦════════════════════════════╦══════════╦══════════╣"
PROC_ROW_SEP="╠════════╬════════════════════════════╬══════════╬══════════╣"
PROC_BTM="╚════════╩════════════════════════════╩══════════╩══════════╝"

function print_row() {
    printf "\033[1;36m║\033[0m \033[0;32m%-19s\033[0m \033[1;36m║\033[0m \033[1;33m%-35s\033[0m \033[1;36m║\033[0m\n" "$1" "$2"
}

function print_proc_row() {
    printf "\033[1;36m║\033[0m \033[0;32m%-6s\033[0m \033[1;36m║\033[0m \033[1;33m%-26s\033[0m \033[1;36m║\033[0m \033[1;33m%-8s\033[0m \033[1;36m║\033[0m \033[1;33m%-8s\033[0m \033[1;36m║\033[0m\n" "$1" "$2" "$3" "$4"
}

# ─── Data collectors (return clean values, no printing) ─────────────────────
function get_os_name() {
    grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"'
}

function get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
    awk '{printf "%.1f%%", 100 - $1}'
}

function get_memory_usage() {
    free -h | awk '/^Mem:/ {printf "%s / %s", $3, $2}'
}

function get_memory_percent() {
    free | awk '/^Mem:/ {printf "%.1f%%", $3/$2*100}'
}

function get_disk_usage() {
    df -h | awk '$NF=="/"{printf "%s / %s (%s)", $3, $2, $5}'
}

function get_running_processes() {
    ps --no-headers -e | wc -l
}

function get_system_uptime() {
    uptime -p
}

function get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | xargs
}

function get_logged_users() {
    who | wc -l
}

function get_failed_logins() {
    if [[ -r /var/log/auth.log ]]; then
        grep -c "Failed password" /var/log/auth.log
    elif [[ -r /var/log/secure ]]; then
        grep -c "Failed password" /var/log/secure
    else
        echo "N/A"
    fi
}

# ─── Welcome screen ──────────────────────────────────────────────────────────
function welcome() {
    clear
    echo -e "${BOLD}${CYAN}===== Welcome to the system checker script! =====${NC}"
    sleep 1
    echo -e "System: ${YELLOW}$(get_os_name)${NC}\n"
    sleep 1
    echo "Metrics to collect:"
    local metrics=("CPU Usage" "Memory Usage" "Disk Usage" "Top 5 Processes (CPU)" "Top 5 Processes (MEM)" "Uptime · Load · Users · Failed Logins")
    for m in "${metrics[@]}"; do
        echo "  · $m"
        sleep 0.3
    done
}

# ─── Main table display ──────────────────────────────────────────────────────
function display_stats() {
    echo -e "\n${CYAN}Gathering system stats, please wait...${NC}"

    local os cpu mem mem_pct disk procs uptime_val load users failed
    os=$(get_os_name)
    cpu=$(get_cpu_usage)
    mem=$(get_memory_usage)
    mem_pct=$(get_memory_percent)
    disk=$(get_disk_usage)
    procs=$(get_running_processes)
    uptime_val=$(get_system_uptime)
    load=$(get_load_average)
    users=$(get_logged_users)
    failed=$(get_failed_logins)

    clear
    echo -e "${BOLD}${CYAN}${TOP_BORDER}${NC}"
    printf "${BOLD}${CYAN}║${NC} ${BOLD}%-57s${NC} ${BOLD}${CYAN}║${NC}\n" "SERVER PERFORMANCE STATS"
    printf "${BOLD}${CYAN}║${NC} %-57s ${BOLD}${CYAN}║${NC}\n" "OS: $os"
    echo -e "${BOLD}${CYAN}${HDR_SPLIT}${NC}"
    printf "${BOLD}${CYAN}║${NC} ${BOLD}${CYAN}%-19s${NC} ${BOLD}${CYAN}║${NC} ${BOLD}${CYAN}%-35s${NC} ${BOLD}${CYAN}║${NC}\n" "METRIC" "VALUE"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
    print_row "CPU Usage"          "$cpu"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
    print_row "Memory"             "$mem ($mem_pct)"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
    print_row "Disk (root)"        "$disk"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
    print_row "Running Processes"  "$procs"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
    print_row "System Uptime"      "$uptime_val"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
    print_row "Load Average"       "$load"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
    print_row "Logged In Users"    "$users"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
}

function display_top_processes() {
    local sort_key="$1" title="$2" col3_label="$3"

    echo ""
    echo -e "${BOLD}${CYAN}${TOP_BORDER}${NC}"
    printf "${BOLD}${CYAN}║${NC} ${BOLD}%-57s${NC} ${BOLD}${CYAN}║${NC}\n" "$title"
    echo -e "${BOLD}${CYAN}${PROC_HDR_SEP}${NC}"
    printf "\033[1;36m║\033[0m \033[1m%-6s\033[0m \033[1;36m║\033[0m \033[1m%-26s\033[0m \033[1;36m║\033[0m \033[1m%-8s\033[0m \033[1;36m║\033[0m \033[1m%-8s\033[0m \033[1;36m║\033[0m\n" "PID" "COMMAND" "$col3_label" "MEM %"
    echo -e "${BOLD}${CYAN}${PROC_ROW_SEP}${NC}"

    mapfile -t rows < <(ps aux --sort="$sort_key" | awk 'NR>1 && NR<=6 {printf "%s\t%s\t%s\t%s\n", $2, $11, $3, $4}')
    for i in "${!rows[@]}"; do
        IFS=$'\t' read -r pid cmd cpu mem <<< "${rows[$i]}"
        print_proc_row "$pid" "$(basename "$cmd")" "$cpu" "$mem"
        if [[ $i -lt $((${#rows[@]}-1)) ]]; then
            echo -e "${BOLD}${CYAN}${PROC_ROW_SEP}${NC}"
        fi
    done
    echo -e "${BOLD}${CYAN}${PROC_BTM}${NC}"
}

function display_failed_logins() {
    local log_file=""
    if [[ -r /var/log/auth.log ]]; then
        log_file="/var/log/auth.log"
    elif [[ -r /var/log/secure ]]; then
        log_file="/var/log/secure"
    else
        return
    fi

    echo ""
    echo -e "${BOLD}${CYAN}${TOP_BORDER}${NC}"
    printf "${BOLD}${CYAN}║${NC} ${BOLD}%-57s${NC} ${BOLD}${CYAN}║${NC}\n" "FAILED LOGINS BY USER"
    echo -e "${BOLD}${CYAN}${HDR_SPLIT}${NC}"
    printf "\033[1;36m║\033[0m \033[1m%-19s\033[0m \033[1;36m║\033[0m \033[1m%-35s\033[0m \033[1;36m║\033[0m\n" "USER" "FAILED ATTEMPTS"
    echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"

    mapfile -t rows < <(grep "Failed password" "$log_file" | \
        awk '{for(i=1;i<=NF;i++){if($i=="for"&&$(i+1)=="invalid"){print $(i+2);break}if($i=="for"&&$(i+1)!="invalid"){print $(i+1);break}}}' | \
        sort | uniq -c | sort -rn | awk '{print $2"\t"$1}')

    if [[ ${#rows[@]} -eq 0 ]]; then
        print_row "(none)" "0 failed attempts"
    else
        for i in "${!rows[@]}"; do
            IFS=$'\t' read -r user count <<< "${rows[$i]}"
            print_row "$user" "$count"
            if [[ $i -lt $((${#rows[@]}-1)) ]]; then
                echo -e "${BOLD}${CYAN}${ROW_SEP}${NC}"
            fi
        done
    fi
    echo -e "${BOLD}${CYAN}${BTM_BORDER}${NC}"
}

# ─── Entry point ─────────────────────────────────────────────────────────────
welcome
echo ""
echo -e "Press ${BOLD}Enter${NC} to start..."
read
display_stats
display_top_processes "-%cpu" "TOP 5 PROCESSES BY CPU" "CPU %"
display_top_processes "-%mem" "TOP 5 PROCESSES BY MEMORY" "CPU %"
display_failed_logins
echo ""
echo -e "${BOLD}${CYAN}===== System check complete! — $(date '+%A, %B %d %Y  %H:%M:%S') =====${NC}"
echo ""
