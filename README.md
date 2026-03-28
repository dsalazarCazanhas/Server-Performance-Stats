# Server Performance Stats

A bash script that collects and displays server metrics in a formatted table.

## Usage

```bash
chmod +x server-stats.sh
./server-stats.sh
```

## Metrics

| Metric | Description |
|--------|-------------|
| CPU Usage | Total CPU usage % |
| Memory | Used / Total with percentage |
| Disk (root) | Used / Total with percentage |
| Load Average | 1, 5, and 15-minute averages |
| Running Processes | Total number of active processes |
| System Uptime | Time since last boot |
| Logged In Users | Number of active sessions |
| Failed Logins | Count from `/var/log/auth.log` |
| Top 5 by CPU | Processes sorted by CPU usage |
| Top 5 by Memory | Processes sorted by memory usage |

## Requirements

`bash`, `top`, `free`, `df`, `ps`, `uptime`, `who`

---
> A journey to grow up from [Roadmap.sh](https://roadmap.sh/projects/ecommerce-api)
