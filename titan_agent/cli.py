import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CFG = ROOT / "titan-agent.json"
STATE = ROOT / ".titan" / "state.json"
LOGDIR = ROOT / ".titan" / "logs"
PROMPTDIR = ROOT / ".titan" / "prompts"
RESULTDIR = ROOT / ".titan" / "results"
TASKSDIR = ROOT / ".titan" / "tasks"

DEFAULT_CONFIG = {
    "agent_command": "agy",
    "default_model": "gemini-3.6-flash-medium",
    "timeout_minutes": 20,
    "verify_timeout_seconds": 600,
    "max_repairs": 2,
    "print_timeout": "20m",
    "output_format": "json",
    "dangerously_skip_permissions": False,
    "protected_prefixes": [
        "project_titan/apps/quizforge_ai",
        "project_titan/apps/quizforge",
        "packages/quizforge"
    ],
    "allowed_scope": [
        "project_titan/apps/titan_reader",
        "project_titan/docs/applications/titan_reader"
    ]
}

FORBIDDEN_OPERATIONS = [
    "git add .",
    "git add -a",
    "git add -all",
    "git add -A",
    "git reset --hard",
    "git clean",
    "git push",
    "git checkout .",
    "git restore ."
]


def load_json(path: Path, default=None):
    if not path.exists():
        return default if default is not None else {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default if default is not None else {}


def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def run_shell(cmd: str, timeout: int = 60, cwd: Path = ROOT):
    """Run shell command for git status/diff inspection or simple subprocesses."""
    try:
        p = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout
        )
        return p.returncode, p.stdout
    except Exception as e:
        return 1, str(e)


def file_hash(path: Path):
    """Computes SHA256 of a file if it exists."""
    if not path.is_file():
        return None
    try:
        h = hashlib.sha256()
        h.update(path.read_bytes())
        return h.hexdigest()
    except Exception:
        return None


def parse_git_status(status_text: str):
    """
    Parses `git status --short` output into a dict:
    { "relative/path": { "code": "M ", "hash": "<sha256>" } }
    """
    entries = {}
    for line in status_text.splitlines():
        line = line.rstrip()
        if len(line) < 3:
            continue
        code = line[:2]
        path_str = line[3:].strip()
        if " -> " in path_str:
            path_str = path_str.split(" -> ")[-1].strip()
        norm_path = path_str.replace("\\", "/")
        full_path = ROOT / norm_path
        entries[norm_path] = {
            "code": code,
            "hash": file_hash(full_path)
        }
    return entries


def compute_git_delta(before_map: dict, after_map: dict):
    """
    Compares before and after git status maps and classifies changes into:
    - preexisting_changes: items before
    - newly_changed_files: files modified or content-altered during execution
    - newly_created_files: untracked / added files created during execution
    - deleted_files: files deleted during execution
    """
    preexisting = [
        {"path": p, "status": v["code"].strip()}
        for p, v in before_map.items()
    ]

    newly_created = []
    newly_changed = []
    deleted = []

    # Check entries in after_map
    for p, info in after_map.items():
        code = info["code"]
        current_hash = info["hash"]
        if p not in before_map:
            # Entirely new entry
            if "?" in code or "A" in code:
                newly_created.append(p)
            elif "D" in code:
                deleted.append(p)
            else:
                newly_changed.append(p)
        else:
            # Existed in before_map - check if it changed
            prev_info = before_map[p]
            if prev_info["code"] != code or prev_info["hash"] != current_hash:
                if "D" in code:
                    deleted.append(p)
                else:
                    newly_changed.append(p)

    # Check for paths in before_map that disappeared or became deleted
    for p, prev_info in before_map.items():
        if p not in after_map:
            full_path = ROOT / p
            if not full_path.exists():
                deleted.append(p)

    all_changed = sorted(list(set(newly_created + newly_changed + deleted)))
    return {
        "preexisting_changes": preexisting,
        "newly_created_files": sorted(list(set(newly_created))),
        "newly_changed_files": sorted(list(set(newly_changed))),
        "deleted_files": sorted(list(set(deleted))),
        "all_changed_files": all_changed
    }


def check_scope_violations(changed_files: list, task_scope: list, cfg: dict):
    """
    Evaluates if any newly changed files violate protected paths or task scope.
    """
    protected = cfg.get("protected_prefixes", [])
    violations = []

    for f in changed_files:
        # Ignore .titan/ internal orchestrator records
        if f.startswith(".titan/"):
            continue

        # Check protected prefixes from global configuration
        is_protected = False
        for p in protected:
            p_norm = p.replace("\\", "/").rstrip("/")
            if f == p_norm or f.startswith(p_norm + "/"):
                violations.append(f)
                is_protected = True
                break
        if is_protected:
            continue

        # If task scope is specified, check against task scope
        if task_scope:
            in_scope = False
            for s in task_scope:
                s_norm = s.replace("\\", "/").rstrip("/")
                if f == s_norm or f.startswith(s_norm + "/"):
                    in_scope = True
                    break
            if not in_scope:
                violations.append(f)

    return sorted(list(set(violations)))


def extract_json(text: str):
    """
    Extracts and parses JSON from agy stdout.
    Tolerates leading/trailing non-JSON logging or terminal output.
    """
    text = text.strip()
    if not text:
        return {"status": "ERROR", "error": "Empty agy output.", "raw": text}

    try:
        return json.loads(text)
    except Exception:
        pass

    # Try finding outermost JSON object
    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end != -1 and end > start:
        candidate = text[start:end + 1]
        try:
            return json.loads(candidate)
        except Exception:
            pass

    return {
        "status": "ERROR",
        "error": "Could not parse agy JSON output.",
        "raw": text
    }


def resolve_model(models: list, repair_count: int, default_model: str = "gemini-3.6-flash-medium") -> str:
    """
    Model escalation strategy:
    Attempt 1 (repair_count = 0) -> models[0]
    Repair 1 (repair_count = 1) -> models[0] (same model)
    Repair 2 (repair_count = 2) -> models[1] if configured else models[0]
    Repair k (repair_count = k) -> models[min(k-1, len(models)-1)]
    """
    if not models:
        return default_model
    if repair_count <= 1:
        return models[0]
    idx = min(repair_count - 1, len(models) - 1)
    return models[idx]


def execute_agy_turn(
    task_name: str,
    turn_name: str,
    prompt_text: str,
    model: str,
    conversation_id: str = None,
    continue_last: bool = False,
    timeout_mins: int = 20,
    cfg: dict = None
):
    """
    Executes a single agy turn via subprocess, handles exact timeout kill,
    parses JSON output, saves turn artifacts and returns execution summary.
    """
    if cfg is None:
        cfg = load_json(CFG, DEFAULT_CONFIG)

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    turn_id = f"{stamp}-{task_name}-{turn_name}"
    prompt_file = PROMPTDIR / f"{turn_id}.md"
    result_file = RESULTDIR / f"{turn_id}.json"
    log_file = LOGDIR / f"{turn_id}.log"

    PROMPTDIR.mkdir(parents=True, exist_ok=True)
    RESULTDIR.mkdir(parents=True, exist_ok=True)
    LOGDIR.mkdir(parents=True, exist_ok=True)
    prompt_file.write_text(prompt_text, encoding="utf-8")

    prompt_rel_path = str(prompt_file.relative_to(ROOT)).replace("\\", "/")
    result_rel_path = str(result_file.relative_to(ROOT)).replace("\\", "/")

    output_format = cfg.get("output_format", "json")
    print_timeout = cfg.get("print_timeout", "20m")

    cmd = ["agy", "-p", prompt_text, "--output-format", output_format, "--print-timeout", print_timeout]
    if model:
        cmd += ["--model", model]
    if cfg.get("effort"):
        cmd += ["--effort", cfg["effort"]]
    if conversation_id:
        cmd += ["--conversation", conversation_id]
    elif continue_last:
        cmd += ["--continue"]
    if cfg.get("dangerously_skip_permissions"):
        cmd += ["--dangerously-skip-permissions"]

    timeout_seconds = timeout_mins * 60
    start_time = time.time()
    started_iso = datetime.now().isoformat(timespec="seconds")
    is_timeout = False
    stdout = ""
    stderr = ""
    rc = 0

    proc = subprocess.Popen(
        cmd,
        cwd=ROOT,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace"
    )
    try:
        stdout, stderr = proc.communicate(timeout=timeout_seconds)
        rc = proc.returncode
    except subprocess.TimeoutExpired:
        is_timeout = True
        rc = 124
        # Terminate only the exact agy child process
        proc.kill()
        try:
            stdout, stderr = proc.communicate(timeout=5)
        except Exception:
            pass

    elapsed_seconds = round(time.time() - start_time, 2)
    finished_iso = datetime.now().isoformat(timespec="seconds")

    if is_timeout:
        parsed = {
            "status": "TIMEOUT",
            "error": f"Turn exceeded timeout limit of {timeout_mins} minutes.",
            "response": "",
            "conversation_id": conversation_id,
            "duration_seconds": elapsed_seconds,
            "num_turns": 0,
            "usage": {}
        }
    else:
        parsed = extract_json(stdout)

    # Save turn result
    parsed["_orchestrator"] = {
        "task_name": task_name,
        "turn_name": turn_name,
        "model": model,
        "prompt_file": prompt_rel_path,
        "started_at": started_iso,
        "finished_at": finished_iso,
        "elapsed_seconds": elapsed_seconds,
        "exit_code": rc,
        "stderr": (stderr or "")[-5000:]
    }
    save_json(result_file, parsed)

    # Save turn log
    log_content = (
        f"TITAN AGENT TURN LOG\n"
        f"Task: {task_name}\n"
        f"Turn: {turn_name}\n"
        f"Model: {model}\n"
        f"Started: {started_iso}\n"
        f"Finished: {finished_iso}\n"
        f"Elapsed: {elapsed_seconds}s\n"
        f"Exit Code: {rc}\n"
        f"----------------------------------------\n"
        f"STDOUT:\n{stdout}\n"
        f"----------------------------------------\n"
        f"STDERR:\n{stderr}\n"
    )
    log_file.write_text(log_content, encoding="utf-8")

    return {
        "parsed": parsed,
        "stdout": stdout,
        "stderr": stderr,
        "exit_code": rc,
        "is_timeout": is_timeout,
        "elapsed_seconds": elapsed_seconds,
        "result_file": result_rel_path,
        "prompt_file": prompt_rel_path,
        "started_at": started_iso,
        "finished_at": finished_iso,
        "conversation_id": parsed.get("conversation_id") or conversation_id
    }


def run_verification(verify_commands: list, default_timeout_seconds: int = 600):
    """
    Executes each verification command with exact subprocess timeout handling.
    Captures command, exit code, stdout, stderr, duration.
    """
    results = []
    all_passed = True

    for item in verify_commands:
        if isinstance(item, str):
            cmd_str = item
            cmd_cwd = ROOT
            timeout_sec = default_timeout_seconds
        elif isinstance(item, dict):
            cmd_str = item.get("command", "")
            cwd_val = item.get("cwd")
            cmd_cwd = (ROOT / cwd_val) if cwd_val else ROOT
            timeout_sec = item.get("timeout_seconds", default_timeout_seconds)
        else:
            continue

        if not cmd_str.strip():
            continue

        start_t = time.time()
        is_timeout = False
        rc = 0
        stdout = ""
        stderr = ""

        try:
            proc = subprocess.Popen(
                cmd_str,
                shell=True,
                cwd=cmd_cwd,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding="utf-8",
                errors="replace"
            )
            stdout, stderr = proc.communicate(timeout=timeout_sec)
            rc = proc.returncode
        except subprocess.TimeoutExpired:
            is_timeout = True
            rc = 124
            proc.kill()
            try:
                stdout, stderr = proc.communicate(timeout=5)
            except Exception:
                pass

        duration = round(time.time() - start_t, 2)
        passed = (rc == 0 and not is_timeout)
        if not passed:
            all_passed = False

        cwd_rel = str(cmd_cwd.relative_to(ROOT)).replace("\\", "/") if cmd_cwd != ROOT else "."
        results.append({
            "command": cmd_str,
            "cwd": cwd_rel,
            "exit_code": rc,
            "passed": passed,
            "is_timeout": is_timeout,
            "duration_seconds": duration,
            "stdout": stdout,
            "stderr": stderr
        })

    return all_passed, results


def format_verification_failure_report(verify_results: list) -> str:
    """Formats verification failure output for injection into repair prompt."""
    lines = []
    for i, r in enumerate(verify_results, 1):
        status_str = "PASSED" if r["passed"] else ("TIMEOUT" if r["is_timeout"] else f"FAILED (exit code {r['exit_code']})")
        lines.append(f"Command #{i}: `{r['command']}` (cwd: `{r['cwd']}`) -> {status_str} in {r['duration_seconds']}s")
        if not r["passed"]:
            if r["stdout"].strip():
                stdout_snippet = r["stdout"].strip()
                if len(stdout_snippet) > 4000:
                    stdout_snippet = stdout_snippet[:2000] + "\n... [truncated] ...\n" + stdout_snippet[-2000:]
                lines.append("STDOUT:")
                lines.append(f"```\n{stdout_snippet}\n```")
            if r["stderr"].strip():
                stderr_snippet = r["stderr"].strip()
                if len(stderr_snippet) > 4000:
                    stderr_snippet = stderr_snippet[:2000] + "\n... [truncated] ...\n" + stderr_snippet[-2000:]
                lines.append("STDERR:")
                lines.append(f"```\n{stderr_snippet}\n```")
    return "\n".join(lines)


def print_dry_run(task: dict, cfg: dict):
    """Outputs execution plan without invoking agent."""
    name = task.get("name", "unnamed-task")
    scope = task.get("scope", cfg.get("allowed_scope", []))
    models = task.get("models", [cfg.get("default_model", "gemini-3.6-flash-medium")])
    verify_cmds = task.get("verify", [])
    timeout_mins = task.get("timeout_minutes", cfg.get("timeout_minutes", 20))
    verify_timeout = task.get("verify_timeout_seconds", cfg.get("verify_timeout_seconds", 600))
    max_repairs = task.get("max_repairs", cfg.get("max_repairs", 2))

    print("============================================================")
    print("TITAN TASK DRY RUN")
    print("============================================================")
    print(f"Task: {name}")
    print(f"Scope ({len(scope)} path{'s' if len(scope) != 1 else ''}):")
    for s in scope:
        print(f"  - {s}")
    print("Model Sequence:")
    print(f"  - Attempt 1 (Initial): {resolve_model(models, 0, cfg.get('default_model'))}")
    for r in range(1, max_repairs + 1):
        print(f"  - Repair {r}: {resolve_model(models, r, cfg.get('default_model'))}")
    print(f"Verification Commands ({len(verify_cmds)}):")
    for i, c in enumerate(verify_cmds, 1):
        cmd_text = c if isinstance(c, str) else c.get("command", "")
        cwd_text = f" (cwd: {c.get('cwd')})" if isinstance(c, dict) and "cwd" in c else ""
        print(f"  {i}. {cmd_text}{cwd_text}")
    print(f"Agent Timeout: {timeout_mins} minutes")
    print(f"Verification Timeout: {verify_timeout} seconds per command")
    print(f"Maximum Repair Attempts: {max_repairs}")
    print("============================================================")


def task_command(args):
    """
    Executes the full V3 autonomous implementation/verification/repair loop.
    """
    cfg = load_json(CFG, DEFAULT_CONFIG)

    # 1. Load task definition
    t_path = Path(args.task_file)
    if not t_path.is_absolute():
        t_path = ROOT / t_path
    if not t_path.exists():
        raise SystemExit(f"Error: Task file not found: {t_path}")

    task = load_json(t_path, None)
    if not task or not isinstance(task, dict):
        raise SystemExit(f"Error: Failed to parse valid JSON task from {t_path}")

    task_name = task.get("name") or t_path.stem
    task_scope = task.get("scope", cfg.get("allowed_scope", []))
    verify_commands = task.get("verify", [])
    max_repairs = int(task.get("max_repairs", cfg.get("max_repairs", 2)))
    models = task.get("models") or [cfg.get("default_model", "gemini-3.6-flash-medium")]
    timeout_mins = int(task.get("timeout_minutes", cfg.get("timeout_minutes", 20)))
    verify_timeout = int(task.get("verify_timeout_seconds", cfg.get("verify_timeout_seconds", 600)))

    # 2. Dry run handling
    if args.dry_run:
        print_dry_run(task, cfg)
        return

    # 3. Resolve initial prompt
    if task.get("prompt"):
        initial_prompt = task["prompt"]
    elif task.get("prompt_file"):
        pf = Path(task["prompt_file"])
        if not pf.is_absolute():
            pf = ROOT / pf
        if not pf.exists():
            raise SystemExit(f"Error: Prompt file referenced in task not found: {pf}")
        initial_prompt = pf.read_text(encoding="utf-8")
    else:
        raise SystemExit("Error: Task definition must specify 'prompt' or 'prompt_file'.")

    # Safety check for forbidden git operations in prompt
    lower_prompt = initial_prompt.lower()
    bad_ops = [op for op in FORBIDDEN_OPERATIONS if op in lower_prompt]
    if bad_ops:
        raise SystemExit(f"BLOCKED: Task prompt contains forbidden Git operation(s): {bad_ops}")

    # 4. Record baseline Git state before any agent invocation
    before_rc, before_raw = run_shell("git status --short")
    before_map = parse_git_status(before_raw)

    result_files = []
    conversation_id = None
    started_at = datetime.now().isoformat(timespec="seconds")

    # Initialize state
    state = load_json(STATE, {})
    state.update({
        "project": "TITAN",
        "task": task_name,
        "current_task": task_name,
        "phase": "initial_implementation",
        "attempt": 0,
        "model": resolve_model(models, 0, cfg.get("default_model")),
        "conversation_id": None,
        "verification_status": "PENDING",
        "repair_count": 0,
        "scope_violation": False,
        "started_at": started_at,
        "finished_at": None,
        "result_files": [],
        "changed_files": [],
        "preexisting_changes": [
            {"path": p, "status": v["code"].strip()}
            for p, v in before_map.items()
        ],
        "status": "running"
    })
    save_json(STATE, state)

    print(f"\n============================================================")
    print(f"TITAN V3 ORCHESTRATOR — TASK: {task_name}")
    print(f"============================================================")

    # ------------------------------------------------------------
    # Turn 0: Initial Implementation Turn
    # ------------------------------------------------------------
    initial_model = resolve_model(models, 0, cfg.get("default_model"))
    print(f"\n>>> [PHASE 1] Initial Implementation (Model: {initial_model})")

    turn0_res = execute_agy_turn(
        task_name=task_name,
        turn_name="attempt0",
        prompt_text=initial_prompt,
        model=initial_model,
        timeout_mins=timeout_mins,
        cfg=cfg
    )
    result_files.append(turn0_res["result_file"])
    conversation_id = turn0_res["conversation_id"]

    # Evaluate Git changes & scope safety
    after_rc, after_raw = run_shell("git status --short")
    after_map = parse_git_status(after_raw)
    delta = compute_git_delta(before_map, after_map)
    violations = check_scope_violations(delta["all_changed_files"], task_scope, cfg)

    state.update({
        "conversation_id": conversation_id,
        "result_files": result_files,
        "changed_files": delta["all_changed_files"],
        "scope_violation": bool(violations)
    })
    save_json(STATE, state)

    if violations:
        print(f"\n!!! SCOPE VIOLATION DETECTED: {violations} !!!")
        state.update({
            "status": "SCOPE_VIOLATION",
            "phase": "scope_violation",
            "finished_at": datetime.now().isoformat(timespec="seconds")
        })
        save_json(STATE, state)
        raise SystemExit(2)

    if turn0_res["is_timeout"]:
        print(f"\n!!! INITIAL TURN TIMED OUT !!!")
        state.update({
            "status": "TIMEOUT",
            "phase": "timeout",
            "finished_at": datetime.now().isoformat(timespec="seconds")
        })
        save_json(STATE, state)
        raise SystemExit(124)

    # ------------------------------------------------------------
    # Verification & Bounded Repair Loop
    # ------------------------------------------------------------
    repair_count = 0
    verification_passed = False

    while True:
        # Run verification commands
        state.update({"phase": "verification", "verification_status": "RUNNING"})
        save_json(STATE, state)

        print(f"\n>>> Running Verification ({len(verify_commands)} checks)...")
        v_passed, v_results = run_verification(verify_commands, default_timeout_seconds=verify_timeout)

        for r in v_results:
            tag = "PASS" if r["passed"] else ("TIMEOUT" if r["is_timeout"] else f"FAIL ({r['exit_code']})")
            print(f"  [{tag}] {r['command']} ({r['duration_seconds']}s)")

        if v_passed:
            verification_passed = True
            print(f"\n>>> VERIFICATION SUCCESSFUL! All checks passed.")
            break

        # Verification Failed
        print(f"\n>>> VERIFICATION FAILED (Attempt {repair_count + 1})")
        if repair_count >= max_repairs:
            print(f"\n>>> Maximum repair attempts ({max_repairs}) exhausted.")
            break

        # Proceed to Repair Turn
        repair_count += 1
        repair_model = resolve_model(models, repair_count, cfg.get("default_model"))
        print(f"\n>>> [REPAIR TURN {repair_count}/{max_repairs}] Escalating to model: {repair_model}")

        state.update({
            "phase": f"repair_{repair_count}",
            "attempt": repair_count,
            "model": repair_model,
            "repair_count": repair_count,
            "verification_status": "FAILED"
        })
        save_json(STATE, state)

        failure_report = format_verification_failure_report(v_results)
        scope_str = "\n".join(f"- {s}" for s in task_scope) if task_scope else "(all non-protected files)"

        repair_prompt = (
            f"# TITAN REPAIR REQUEST (Attempt {repair_count}/{max_repairs})\n"
            f"Task: {task_name}\n"
            f"Authorized Scope:\n{scope_str}\n\n"
            f"The verification commands executed by the orchestrator failed:\n\n"
            f"{failure_report}\n\n"
            f"Please diagnose the failures and repair ONLY files within the authorized scope:\n"
            f"{scope_str}\n\n"
            f"Do NOT modify any files outside this scope.\n"
            f"Do NOT execute git add, git commit, git push, or git reset."
        )

        turn_repair_res = execute_agy_turn(
            task_name=task_name,
            turn_name=f"repair{repair_count}",
            prompt_text=repair_prompt,
            model=repair_model,
            conversation_id=conversation_id,
            continue_last=bool(not conversation_id),
            timeout_mins=timeout_mins,
            cfg=cfg
        )
        result_files.append(turn_repair_res["result_file"])
        conversation_id = turn_repair_res["conversation_id"]

        # Scope safety check after repair turn
        after_rc, after_raw = run_shell("git status --short")
        after_map = parse_git_status(after_raw)
        delta = compute_git_delta(before_map, after_map)
        violations = check_scope_violations(delta["all_changed_files"], task_scope, cfg)

        state.update({
            "conversation_id": conversation_id,
            "result_files": result_files,
            "changed_files": delta["all_changed_files"],
            "scope_violation": bool(violations)
        })
        save_json(STATE, state)

        if violations:
            print(f"\n!!! SCOPE VIOLATION DETECTED DURING REPAIR: {violations} !!!")
            state.update({
                "status": "SCOPE_VIOLATION",
                "phase": "scope_violation",
                "finished_at": datetime.now().isoformat(timespec="seconds")
            })
            save_json(STATE, state)
            raise SystemExit(2)

        if turn_repair_res["is_timeout"]:
            print(f"\n!!! REPAIR TURN {repair_count} TIMED OUT !!!")

    # Final status determination
    finished_at = datetime.now().isoformat(timespec="seconds")
    if verification_passed:
        final_status = "SUCCESS"
        phase = "completed"
        v_status = "PASSED"
    else:
        final_status = "VERIFICATION_FAILED"
        phase = "failed"
        v_status = "FAILED"

    state.update({
        "status": final_status,
        "phase": phase,
        "verification_status": v_status,
        "finished_at": finished_at
    })
    save_json(STATE, state)

    print(f"\n============================================================")
    print(f"TITAN TASK FINAL STATUS: {final_status}")
    print(f"Repairs: {repair_count}/{max_repairs}")
    print(f"Result files ({len(result_files)}): {result_files}")
    print(f"============================================================")

    if not verification_passed:
        raise SystemExit(1)


def init_command(_):
    if not CFG.exists():
        save_json(CFG, DEFAULT_CONFIG)
    state = {
        "project": "TITAN",
        "status": "ready",
        "task": None,
        "current_task": None,
        "phase": "idle",
        "attempt": 0,
        "model": load_json(CFG, DEFAULT_CONFIG).get("default_model", "gemini-3.6-flash-medium"),
        "conversation_id": None,
        "verification_status": "NONE",
        "repair_count": 0,
        "scope_violation": False,
        "started_at": None,
        "finished_at": None,
        "result_files": [],
        "changed_files": [],
        "preexisting_changes": []
    }
    save_json(STATE, state)
    for d in (LOGDIR, PROMPTDIR, RESULTDIR, TASKSDIR):
        d.mkdir(parents=True, exist_ok=True)
    print("TITAN Agent Orchestrator initialized.")


def status_command(_):
    state = load_json(STATE, {})
    print(json.dumps(state, indent=2))
    print("\n=== CURRENT GIT STATUS ===")
    rc, out = run_shell("git status --short")
    print(out.rstrip() if out.strip() else "(working tree clean)")


def models_command(_):
    """
    Invokes `agy models` as the authoritative source of truth and displays available models.
    """
    proc = subprocess.run(
        ["agy", "models"],
        cwd=ROOT,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=30
    )
    if proc.stdout:
        print(proc.stdout.rstrip())
    if proc.returncode != 0:
        if proc.stderr:
            print(proc.stderr.rstrip(), file=sys.stderr)
        raise SystemExit(proc.returncode)


def checkpoint_command(_):
    for c in ("git status --short", "git diff --stat", "git diff --check"):
        rc, out = run_shell(c)
        print(f"> {c}\n{out}")
    print("No staging/commit/push performed.")


def run_task(args):
    cfg = load_json(CFG, DEFAULT_CONFIG)

    # 1. Validate prompt arguments
    if args.prompt and args.prompt_file:
        raise SystemExit("Error: Specify exactly one of --prompt or --prompt-file, not both.")
    if not args.prompt and not args.prompt_file:
        raise SystemExit("Error: Exactly one of --prompt or --prompt-file is required.")

    if args.prompt:
        prompt_text = args.prompt
    else:
        p_path = Path(args.prompt_file)
        if not p_path.is_absolute():
            p_path = ROOT / p_path
        if not p_path.exists():
            raise SystemExit(f"Error: Prompt file not found: {p_path}")
        prompt_text = p_path.read_text(encoding="utf-8")

    if not prompt_text.strip():
        raise SystemExit("Error: Prompt is empty.")

    # 2. Safety filter for forbidden Git operations in prompt
    lower_prompt = prompt_text.lower()
    bad_ops = [op for op in FORBIDDEN_OPERATIONS if op in lower_prompt]
    if bad_ops:
        raise SystemExit(f"BLOCKED: Prompt contains forbidden operation(s): {bad_ops}")

    # 3. Model resolution
    model = args.model or cfg.get("default_model", "gemini-3.6-flash-medium")

    # 4. Record Git state before execution
    before_rc, before_raw = run_shell("git status --short")
    before_map = parse_git_status(before_raw)

    timeout_mins = int(args.timeout or cfg.get("timeout_minutes", 20))

    # 5. Execute single turn
    res = execute_agy_turn(
        task_name=args.name,
        turn_name="single",
        prompt_text=prompt_text,
        model=model,
        conversation_id=args.conversation,
        continue_last=args.continue_last,
        timeout_mins=timeout_mins,
        cfg=cfg
    )

    # 6. Record Git state after execution & compute delta
    after_rc, after_raw = run_shell("git status --short")
    after_map = parse_git_status(after_raw)
    delta = compute_git_delta(before_map, after_map)
    violations = check_scope_violations(delta["all_changed_files"], cfg.get("allowed_scope", []), cfg)

    # 7. Determine final status
    parsed = res["parsed"]
    rc = res["exit_code"]
    if violations:
        final_status = "SCOPE_VIOLATION"
    elif res["is_timeout"]:
        final_status = "TIMEOUT"
    elif rc == 0 and parsed.get("status") == "SUCCESS":
        final_status = "SUCCESS"
    else:
        final_status = parsed.get("status", "FAILED")

    # 8. Update state
    state = load_json(STATE, {})
    state.update({
        "project": "TITAN",
        "status": final_status,
        "task": args.name,
        "current_task": args.name,
        "phase": "single_turn",
        "attempt": 0,
        "model": model,
        "started_at": res["started_at"],
        "finished_at": res["finished_at"],
        "conversation_id": res["conversation_id"],
        "verification_status": "NONE",
        "repair_count": 0,
        "scope_violation": bool(violations),
        "result_files": [res["result_file"]],
        "changed_files": delta["all_changed_files"],
        "preexisting_changes": delta["preexisting_changes"]
    })
    save_json(STATE, state)

    print(f"Result saved: {res['result_file']}")
    print(f"Status: {final_status}")
    if parsed.get("response"):
        print(f"Response:\n{parsed['response'].strip()}")
    if violations:
        print(f"!!! SCOPE VIOLATION DETECTED in paths: {violations} !!!")
        raise SystemExit(2)
    if rc != 0 and final_status != "SUCCESS":
        raise SystemExit(rc)


def main():
    parser = argparse.ArgumentParser(prog="titan-agent", description="TITAN Agent Orchestrator")
    subparsers = parser.add_subparsers(dest="cmd", required=True)

    p_init = subparsers.add_parser("init", help="Initialize TITAN agent state and directories")
    p_init.set_defaults(fn=init_command)

    p_status = subparsers.add_parser("status", help="Show current state and git status")
    p_status.set_defaults(fn=status_command)

    p_models = subparsers.add_parser("models", help="List available models via agy")
    p_models.set_defaults(fn=models_command)

    p_checkpoint = subparsers.add_parser("checkpoint", help="Check working tree diff without staging/committing")
    p_checkpoint.set_defaults(fn=checkpoint_command)

    p_run = subparsers.add_parser("run", help="Run a single-turn task via agy")
    p_run.add_argument("name", help="Name of the task")
    p_run.add_argument("--prompt", help="Literal prompt text")
    p_run.add_argument("--prompt-file", help="Path to prompt file")
    p_run.add_argument("--model", help="Model ID (e.g. gemini-3.6-flash-medium)")
    p_run.add_argument("--continue", dest="continue_last", action="store_true", help="Continue most recent conversation")
    p_run.add_argument("--conversation", help="Resume specific conversation by ID")
    p_run.add_argument("--timeout", type=int, help="Timeout in minutes (default: 20)")
    p_run.set_defaults(fn=run_task)

    p_task = subparsers.add_parser("task", help="Execute bounded implementation/verification/repair loop")
    p_task.add_argument("task_file", help="Path to JSON task definition file")
    p_task.add_argument("--dry-run", action="store_true", help="Print execution plan without invoking agent")
    p_task.set_defaults(fn=task_command)

    args = parser.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
