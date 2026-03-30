#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-MultiClips}"
DURATION_SECONDS="${2:-60}"
INTERVAL_SECONDS="${3:-1}"
OUTPUT_DIR="${4:-performance-results}"

if ! [[ "$DURATION_SECONDS" =~ ^[0-9]+$ ]] || ! [[ "$INTERVAL_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "Duration and interval must be integers."
  echo "Usage: ./scripts/performance_test.sh [AppName] [DurationSeconds] [IntervalSeconds] [OutputDir]"
  exit 1
fi

if [[ "$INTERVAL_SECONDS" -le 0 ]]; then
  echo "Interval must be greater than 0."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
CSV_FILE="$OUTPUT_DIR/perf-$TIMESTAMP.csv"
SUMMARY_FILE="$OUTPUT_DIR/perf-$TIMESTAMP-summary.txt"

PID="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
if [[ -z "$PID" ]]; then
  echo "App '$APP_NAME' is not running. Start the app, then rerun this script."
  exit 1
fi

echo "elapsed_sec,rss_mb,cpu_percent,vsz_mb" > "$CSV_FILE"

echo "Sampling app '$APP_NAME' (pid=$PID) for $DURATION_SECONDS seconds every $INTERVAL_SECONDS second(s)..."

ELAPSED=0
while [[ "$ELAPSED" -le "$DURATION_SECONDS" ]]; do
  if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "Process ended before test completed."
    break
  fi

  # rss and vsz are in kilobytes on macOS.
  SAMPLE="$(ps -p "$PID" -o rss=,%cpu=,vsz= | tr -s ' ')"
  RSS_KB="$(echo "$SAMPLE" | awk '{print $1}')"
  CPU_PCT="$(echo "$SAMPLE" | awk '{print $2}')"
  VSZ_KB="$(echo "$SAMPLE" | awk '{print $3}')"

  RSS_MB="$(awk -v kb="$RSS_KB" 'BEGIN { printf "%.2f", kb/1024 }')"
  VSZ_MB="$(awk -v kb="$VSZ_KB" 'BEGIN { printf "%.2f", kb/1024 }')"

  echo "$ELAPSED,$RSS_MB,$CPU_PCT,$VSZ_MB" >> "$CSV_FILE"

  sleep "$INTERVAL_SECONDS"
  ELAPSED=$((ELAPSED + INTERVAL_SECONDS))
done

awk -F, '
NR == 2 {
  rssMin = $2; rssMax = $2; rssSum = $2;
  cpuMin = $3; cpuMax = $3; cpuSum = $3;
  count = 1;
  next
}
NR > 2 {
  if ($2 < rssMin) rssMin = $2;
  if ($2 > rssMax) rssMax = $2;
  rssSum += $2;

  if ($3 < cpuMin) cpuMin = $3;
  if ($3 > cpuMax) cpuMax = $3;
  cpuSum += $3;

  count++;
}
END {
  if (count == 0) {
    print "No samples collected.";
    exit;
  }

  printf "Samples: %d\n", count;
  printf "RSS MB: min=%.2f max=%.2f avg=%.2f\n", rssMin, rssMax, rssSum / count;
  printf "CPU %%: min=%.2f max=%.2f avg=%.2f\n", cpuMin, cpuMax, cpuSum / count;
}
' "$CSV_FILE" > "$SUMMARY_FILE"

echo "Done."
echo "CSV: $CSV_FILE"
echo "Summary: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

PNG_FILE="${CSV_FILE%.csv}.png"
if command -v python3 >/dev/null 2>&1; then
  if python3 scripts/visualize_performance.py "$CSV_FILE" "$PNG_FILE"; then
    echo "Chart: $PNG_FILE"
  else
    echo "Visualization skipped (python script or matplotlib not available)."
  fi
else
  echo "Visualization skipped (python3 not found)."
fi
