#!/usr/bin/env python3
"""Generate performance charts from a performance_test.sh CSV output."""

from __future__ import annotations

import csv
import os
import sys
from pathlib import Path


def _usage() -> str:
    return (
        "Usage: ./scripts/visualize_performance.py <csv_file> [output_png]\n"
        "Example: ./scripts/visualize_performance.py performance-results/perf-20260319-204401.csv"
    )


def _load_rows(csv_path: Path):
    elapsed = []
    rss = []
    cpu = []
    vsz = []

    with csv_path.open("r", newline="") as f:
        reader = csv.DictReader(f)
        required = {"elapsed_sec", "rss_mb", "cpu_percent", "vsz_mb"}
        if not required.issubset(reader.fieldnames or set()):
            missing = sorted(required - set(reader.fieldnames or []))
            raise ValueError(f"CSV missing required columns: {', '.join(missing)}")

        for row in reader:
            elapsed.append(float(row["elapsed_sec"]))
            rss.append(float(row["rss_mb"]))
            cpu.append(float(row["cpu_percent"]))
            vsz.append(float(row["vsz_mb"]))

    if not elapsed:
        raise ValueError("CSV has no sample rows")

    return elapsed, rss, cpu, vsz


def main() -> int:
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print(_usage())
        return 1

    csv_path = Path(sys.argv[1]).expanduser().resolve()
    if not csv_path.is_file():
        print(f"CSV file not found: {csv_path}")
        return 1

    if len(sys.argv) == 3:
        output_path = Path(sys.argv[2]).expanduser().resolve()
    else:
        output_path = csv_path.with_suffix(".png")

    try:
        elapsed, rss, cpu, vsz = _load_rows(csv_path)
    except Exception as exc:
        print(f"Failed to parse CSV: {exc}")
        return 1

    try:
        import matplotlib.pyplot as plt
    except Exception:
        print("matplotlib is not installed. Install with: python3 -m pip install matplotlib")
        return 2

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(11, 7), sharex=True)
    fig.suptitle(f"MultiClips Performance: {csv_path.name}", fontsize=13)

    ax1.plot(elapsed, rss, color="#1f77b4", linewidth=1.8, label="RSS MB")
    ax1.plot(elapsed, vsz, color="#17becf", linewidth=1.2, linestyle="--", label="VSZ MB")
    ax1.set_ylabel("Memory (MB)")
    ax1.grid(alpha=0.25)
    ax1.legend(loc="upper left")

    ax2.plot(elapsed, cpu, color="#ff7f0e", linewidth=1.6, label="CPU %")
    ax2.set_xlabel("Elapsed Time (sec)")
    ax2.set_ylabel("CPU (%)")
    ax2.grid(alpha=0.25)
    ax2.legend(loc="upper left")

    fig.tight_layout(rect=[0, 0, 1, 0.97])
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=140)
    plt.close(fig)

    print(f"Visualization saved: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
