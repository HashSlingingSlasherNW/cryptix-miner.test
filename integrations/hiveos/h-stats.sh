#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_PATH="$SCRIPT_DIR/h-manifest.conf"

if [[ ! -f "$MANIFEST_PATH" ]]; then
    echo "null"
    exit 0
fi

. "$MANIFEST_PATH"

LOG_FILE="${CUSTOM_LOG_BASENAME}.log"
MAX_DELAY=120
shares_rejected=0

to_mhs() {
    local value="$1"
    local unit="$2"
    case "$unit" in
        "hash/s") echo "$(awk -v v="$value" 'BEGIN{printf "%.6f", v/1000000.0}')" ;;
        "Khash/s") echo "$(awk -v v="$value" 'BEGIN{printf "%.6f", v/1000.0}')" ;;
        "Mhash/s") echo "$(awk -v v="$value" 'BEGIN{printf "%.6f", v}')" ;;
        "Ghash/s") echo "$(awk -v v="$value" 'BEGIN{printf "%.6f", v*1000.0}')" ;;
        "Thash/s") echo "$(awk -v v="$value" 'BEGIN{printf "%.6f", v*1000000.0}')" ;;
        *) echo "0.000000" ;;
    esac
}

json_array() {
    if [[ "$#" -eq 0 ]]; then
        echo "[]"
    else
        printf '%s\n' "$@" | jq -cs '.'
    fi
}

if [[ ! -f "$LOG_FILE" ]]; then
    khs=0
    stats="null"
    echo "$stats"
    exit 0
fi

time_now=$(date +%s)
log_mtime=$(stat -c %Y "$LOG_FILE" 2>/dev/null || echo 0)
diff_time=$((time_now - log_mtime))
if (( diff_time < 0 )); then
    diff_time=$(( -diff_time ))
fi

if (( diff_time >= MAX_DELAY )); then
    khs=0
    stats="null"
    echo "$stats"
    exit 0
fi

shares_accepted=$(grep -oE 'Accepted: [0-9]+' "$LOG_FILE" | awk '{print $2}' | tail -n 1)
shares_accepted=${shares_accepted:-0}

summary_raw=$(grep -E "Current hashrate is [0-9]+([.][0-9]+)? [KMGT]?hash/s" "$LOG_FILE" | tail -n 1)
summary_value=$(echo "$summary_raw" | awk '{print $(NF-1)}')
summary_unit=$(echo "$summary_raw" | awk '{print $NF}')
summary_value=${summary_value:-0}
summary_unit=${summary_unit:-hash/s}
total_hashrate_mhs=$(to_mhs "$summary_value" "$summary_unit")

mapfile -t device_hashes_mhs < <(
    grep -E "Device .*: [0-9]+([.][0-9]+)? [KMGT]?hash/s" "$LOG_FILE" | tail -n 512 | awk '
    {
        unit=$NF
        value=$(NF-1)+0
        key=""
        start=0
        for (i=1; i<=NF; i++) {
            if ($i=="Device") {
                start=i
                break
            }
        }
        if (start==0) next
        for (i=start; i<=NF; i++) {
            token=$i
            has_colon=0
            if (substr(token, length(token), 1)==":") {
                sub(/:$/, "", token)
                has_colon=1
            }
            if (key=="") key=token
            else key=key " " token
            if (has_colon==1) break
        }

        rate=value
        if (unit=="hash/s") rate=value/1000000.0
        else if (unit=="Khash/s") rate=value/1000.0
        else if (unit=="Mhash/s") rate=value
        else if (unit=="Ghash/s") rate=value*1000.0
        else if (unit=="Thash/s") rate=value*1000000.0
        else rate=0

        if (!(key in seen)) {
            seen[key]=1
            order[++count]=key
        }
        last[key]=rate
    }
    END {
        for (i=1; i<=count; i++) {
            key=order[i]
            if (key in last) {
                printf "%.6f\n", last[key]
            }
        }
    }'
)

if [[ "${#device_hashes_mhs[@]}" -eq 0 ]]; then
    device_hashes_mhs=("$total_hashrate_mhs")
fi

if [[ -n "${GPU_STATS_JSON:-}" && -f "${GPU_STATS_JSON:-}" ]]; then
    mapfile -t busids < <(jq -r '.busids[]?' "$GPU_STATS_JSON" 2>/dev/null)
    mapfile -t temps < <(jq -r '.temp[]?' "$GPU_STATS_JSON" 2>/dev/null)
    mapfile -t fans < <(jq -r '.fan[]?' "$GPU_STATS_JSON" 2>/dev/null)
else
    busids=()
    temps=()
    fans=()
fi

hs_arr=()
busid_arr=()
temp_arr=()
fan_arr=()

for (( idx=0; idx<${#device_hashes_mhs[@]}; idx++ )); do
    hs_arr+=("${device_hashes_mhs[$idx]}")

    if (( idx < ${#busids[@]} )); then
        short_busid="${busids[$idx]}"
        if [[ "$short_busid" =~ ^([A-Fa-f0-9]+): ]]; then
            busid_arr+=($((16#${BASH_REMATCH[1]})))
        else
            busid_arr+=(0)
        fi
    else
        busid_arr+=(0)
    fi

    if (( idx < ${#temps[@]} )); then
        temp_arr+=("${temps[$idx]}")
    else
        temp_arr+=(0)
    fi

    if (( idx < ${#fans[@]} )); then
        fan_arr+=("${fans[$idx]}")
    else
        fan_arr+=(0)
    fi
done

hash_json=$(json_array "${hs_arr[@]}")
bus_numbers=$(json_array "${busid_arr[@]}")
fan_json=$(json_array "${fan_arr[@]}")
temp_json=$(json_array "${temp_arr[@]}")

if [[ "$summary_value" == "0" || "$summary_value" == "0.0" || "$summary_value" == "0.000000" ]]; then
    total_hashrate_mhs=$(awk -v values="$(IFS=,; echo "${hs_arr[*]}")" 'BEGIN{
        n=split(values, a, ",")
        s=0
        for (i=1; i<=n; i++) s+=a[i]
        printf "%.6f", s
    }')
fi

total_hashrate_khs=$(awk -v v="$total_hashrate_mhs" 'BEGIN{printf "%.0f", v*1000.0}')
uptime=$(( time_now - $(stat -c %Y "$CUSTOM_CONFIG_FILENAME" 2>/dev/null || echo "$time_now") ))

stats=$(jq -nc \
    --argjson hs "$hash_json" \
    --arg ver "$CUSTOM_VERSION" \
    --argjson bus_numbers "$bus_numbers" \
    --argjson fan "$fan_json" \
    --argjson temp "$temp_json" \
    --arg uptime "$uptime" \
    --arg ths "$total_hashrate_khs" \
    --argjson shares_acc "$shares_accepted" \
    --argjson shares_rej "$shares_rejected" \
    '{hs: $hs, hs_units: "mhs", algo: "cryptix_ox8", ver: $ver, uptime: ($uptime|tonumber), bus_numbers: $bus_numbers, temp: $temp, fan: $fan, ths: ($ths|tonumber), ar: [$shares_acc, $shares_rej]}'
)
khs=$total_hashrate_khs

echo "$stats"
