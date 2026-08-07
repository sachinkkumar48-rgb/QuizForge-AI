"""
GARUDA AI Performance Audit & Profiling Infrastructure (TITAN-S9.0.001).

Provides high-precision latency timing, CPU profiling, memory allocation tracing,
and statistical aggregation (Average, Median, P95, P99, Standard Deviation)
for Project TITAN backend components.
"""
import cProfile
import io
import math
import pstats
import time
import tracemalloc
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional


@dataclass
class MetricSummary:
    count: int
    mean_ms: float
    median_ms: float
    p95_ms: float
    p99_ms: float
    std_dev_ms: float
    min_ms: float
    max_ms: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            "count": self.count,
            "mean_ms": round(self.mean_ms, 3),
            "median_ms": round(self.median_ms, 3),
            "p95_ms": round(self.p95_ms, 3),
            "p99_ms": round(self.p99_ms, 3),
            "std_dev_ms": round(self.std_dev_ms, 3),
            "min_ms": round(self.min_ms, 3),
            "max_ms": round(self.max_ms, 3),
        }


class BenchmarkStatistics:
    """Calculates statistical metrics: Average, Median, P95, P99, StdDev."""

    @staticmethod
    def calculate(samples_ms: List[float]) -> MetricSummary:
        if not samples_ms:
            return MetricSummary(0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

        sorted_samples = sorted(samples_ms)
        n = len(sorted_samples)
        mean_val = sum(sorted_samples) / n

        # Median
        if n % 2 == 1:
            median_val = sorted_samples[n // 2]
        else:
            median_val = (sorted_samples[n // 2 - 1] + sorted_samples[n // 2]) / 2.0

        # Percentiles P95 & P99
        p95_idx = max(0, min(n - 1, math.ceil(0.95 * n) - 1))
        p99_idx = max(0, min(n - 1, math.ceil(0.99 * n) - 1))
        p95_val = sorted_samples[p95_idx]
        p99_val = sorted_samples[p99_idx]

        # Standard Deviation
        variance = sum((x - mean_val) ** 2 for x in sorted_samples) / n
        std_dev_val = math.sqrt(variance)

        return MetricSummary(
            count=n,
            mean_ms=mean_val,
            median_ms=median_val,
            p95_ms=p95_val,
            p99_ms=p99_val,
            std_dev_ms=std_dev_val,
            min_ms=sorted_samples[0],
            max_ms=sorted_samples[-1],
        )


class MemoryProfiler:
    """Traces memory allocations and peak memory usage using tracemalloc."""

    @staticmethod
    def measure(func: Callable[[], Any]) -> Dict[str, Any]:
        tracemalloc.start()
        start_size, _ = tracemalloc.get_traced_memory()
        start_time = time.perf_counter()

        result = func()

        end_time = time.perf_counter()
        current_size, peak_size = tracemalloc.get_traced_memory()
        snapshot = tracemalloc.take_snapshot()
        tracemalloc.stop()

        top_stats = snapshot.statistics("lineno")
        top_allocations = [
            f"{stat.count} blocks, {stat.size / 1024:.2f} KiB: {stat.traceback.format()[0].strip()}"
            for stat in top_stats[:5]
        ]

        return {
            "result": result,
            "duration_ms": round((end_time - start_time) * 1000, 3),
            "allocated_bytes": current_size - start_size,
            "peak_bytes": peak_size,
            "allocated_kb": round((current_size - start_size) / 1024, 2),
            "peak_kb": round(peak_size / 1024, 2),
            "top_allocations": top_allocations,
        }


class CPUProfiler:
    """Profiles function call counts, cumulative execution time, and hot paths using cProfile."""

    @staticmethod
    def profile_function(func: Callable[[], Any], top_n: int = 10) -> Dict[str, Any]:
        profiler = cProfile.Profile()
        profiler.enable()

        result = func()

        profiler.disable()
        s = io.StringIO()
        ps = pstats.Stats(profiler, stream=s).sort_stats("cumulative")
        ps.print_stats(top_n)

        return {
            "result": result,
            "stats_text": s.getvalue(),
        }


class StageTimer:
    """High-precision per-stage latency recorder for multi-step workflows."""

    def __init__(self) -> None:
        self.stage_timings: Dict[str, float] = {}
        self.start_time: Optional[float] = None
        self._current_stage: Optional[str] = None
        self._stage_start: Optional[float] = None

    def start_stage(self, stage_name: str) -> None:
        now = time.perf_counter()
        if self._current_stage and self._stage_start is not None:
            self.stage_timings[self._current_stage] = round((now - self._stage_start) * 1000, 3)
        self._current_stage = stage_name
        self._stage_start = now
        if self.start_time is None:
            self.start_time = now

    def end_stage(self) -> None:
        now = time.perf_counter()
        if self._current_stage and self._stage_start is not None:
            self.stage_timings[self._current_stage] = round((now - self._stage_start) * 1000, 3)
            self._current_stage = None
            self._stage_start = None

    def get_summary(self) -> Dict[str, Any]:
        self.end_stage()
        total_ms = sum(self.stage_timings.values())
        return {
            "total_ms": round(total_ms, 3),
            "stages": self.stage_timings,
        }
