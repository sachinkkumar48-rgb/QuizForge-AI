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
TEMPLATESDIR = ROOT / ".titan" / "templates"

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
            if "?" in code or "A" in code:
                newly_created.append(p)
            elif "D" in code:
                deleted.append(p)
            else:
                newly_changed.append(p)
        else:
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
        if f.startswith(".titan/"):
            continue

        is_protected = False
        for p in protected:
            p_norm = p.replace("\\", "/").rstrip("/")
            if f == p_norm or f.startswith(p_norm + "/"):
                violations.append(f)
                is_protected = True
                break
        if is_protected:
            continue

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


def get_available_models(timeout: int = 30) -> list:
    """
    Invokes `agy models` dynamically and parses the list of available model IDs.
    `agy models` remains the authoritative source of truth.
    """
    try:
        proc = subprocess.run(
            ["agy", "models"],
            cwd=ROOT,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout
        )
        if proc.returncode != 0:
            return []
        models = []
        for line in proc.stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            model_id = line.split()[0]
            models.append(model_id)
        return models
    except Exception:
        return []


def validate_model_preflight(requested_models: list, available_models: list = None) -> tuple:
    """
    Validates that every model in requested_models exists in available_models.
    Returns (is_valid: bool, available_models: list, missing_models: list)
    """
    if available_models is None:
        available_models = get_available_models()

    if not available_models:
        return False, [], list(requested_models)

    missing = [m for m in requested_models if m not in available_models]
    return (len(missing) == 0, available_models, missing)


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


def resolve_template_and_task(task: dict, base_dir: Path = ROOT) -> dict:
    """
    Resolves task definition with template inheritance and variable substitution.
    Deterministic {{var}} replacement with Python standard library only.
    """
    resolved = dict(task)

    if "template" in task and task["template"]:
        tpl_path = Path(task["template"])
        if not tpl_path.is_absolute():
            tpl_path = base_dir / tpl_path
        if not tpl_path.exists():
            raise ValueError(f"Template file not found: {tpl_path}")

        tpl_data = load_json(tpl_path, None)
        if not tpl_data or not isinstance(tpl_data, dict):
            raise ValueError(f"Invalid JSON template in {tpl_path}")

        # Check required variables
        required_vars = tpl_data.get("variables", [])
        provided_vars = task.get("variables", {})
        missing_vars = [v for v in required_vars if v not in provided_vars]
        if missing_vars:
            raise ValueError(f"Missing required template variable(s): {', '.join(missing_vars)}")

        # Inherit fields from template if not overridden in task
        for k in (
            "scope",
            "verification_gates",
            "verify",
            "models",
            "max_repairs",
            "timeout_minutes",
            "verify_timeout_seconds",
            "prompt",
            "prompt_file"
        ):
            if k in tpl_data and k not in resolved:
                resolved[k] = tpl_data[k]

        # Resolve prompt with variable substitution
        prompt_template = resolved.get("prompt")
        if not prompt_template and resolved.get("prompt_file"):
            pf = Path(resolved["prompt_file"])
            if not pf.is_absolute():
                pf = base_dir / pf
            if pf.exists():
                prompt_template = pf.read_text(encoding="utf-8")

        if prompt_template:
            prompt_str = prompt_template
            for var_k, var_v in provided_vars.items():
                prompt_str = prompt_str.replace(f"{{{{{var_k}}}}}", str(var_v))
            resolved["prompt"] = prompt_str
            resolved["prompt_file"] = None

    return resolved


def normalize_verification_gates(task: dict, default_timeout: int = 600) -> list:
    """
    Normalizes V4 verification_gates or V3 verify list into standardized gate structures.
    """
    if "verification_gates" in task and task["verification_gates"]:
        gates = []
        for i, g in enumerate(task["verification_gates"], 1):
            if isinstance(g, dict):
                gates.append({
                    "name": g.get("name", f"Gate {i}"),
                    "command": g.get("command", ""),
                    "cwd": g.get("cwd", "."),
                    "timeout_seconds": int(g.get("timeout_seconds", default_timeout))
                })
            elif isinstance(g, str):
                gates.append({
                    "name": f"Gate {i}",
                    "command": g,
                    "cwd": ".",
                    "timeout_seconds": int(default_timeout)
                })
        return gates
    elif "verify" in task and task["verify"]:
        gates = []
        for i, v in enumerate(task["verify"], 1):
            if isinstance(v, dict):
                gates.append({
                    "name": v.get("name", f"Check #{i}"),
                    "command": v.get("command", ""),
                    "cwd": v.get("cwd", "."),
                    "timeout_seconds": int(v.get("timeout_seconds", default_timeout))
                })
            elif isinstance(v, str):
                gates.append({
                    "name": f"Check #{i}",
                    "command": v,
                    "cwd": ".",
                    "timeout_seconds": int(default_timeout)
                })
        return gates
    return []


def execute_verification_pipeline(gates: list, base_dir: Path = ROOT):
    """
    Executes verification gates sequentially.
    CRITICAL RULE: Stops at the first failure or timeout.
    Returns: (all_passed, results_list, failed_gate)
    """
    results = []
    failed_gate = None
    all_passed = True

    for gate in gates:
        cmd_str = gate["command"]
        cwd_val = gate.get("cwd", ".")
        cmd_cwd = (base_dir / cwd_val).resolve() if cwd_val != "." else base_dir
        timeout_sec = gate.get("timeout_seconds", 600)

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
        if is_timeout:
            status = "TIMEOUT"
            passed = False
        elif rc == 0:
            status = "PASS"
            passed = True
        else:
            status = "FAIL"
            passed = False

        cwd_rel = str(cmd_cwd.relative_to(base_dir)).replace("\\", "/") if cmd_cwd != base_dir else "."
        gate_res = {
            "name": gate["name"],
            "command": cmd_str,
            "cwd": cwd_rel,
            "timeout_seconds": timeout_sec,
            "exit_code": rc,
            "duration_seconds": duration,
            "stdout": stdout,
            "stderr": stderr,
            "status": status,
            "passed": passed,
            "is_timeout": is_timeout
        }
        results.append(gate_res)

        if not passed:
            all_passed = False
            failed_gate = gate_res
            # Stop immediately at first failure
            break

    return all_passed, results, failed_gate


def format_gate_failure_report(results: list, failed_gate: dict) -> str:
    """Formats sequential verification results and diagnostic output for repair."""
    lines = []
    for r in results:
        lines.append(f"Gate '{r['name']}': `{r['command']}` (cwd: `{r['cwd']}`) -> {r['status']} (exit code {r['exit_code']}) in {r['duration_seconds']}s")

    if failed_gate:
        lines.append(f"\n### Diagnostic Details for Failing Gate: '{failed_gate['name']}'")
        lines.append(f"- Command: `{failed_gate['command']}`")
        lines.append(f"- Status: {failed_gate['status']} (exit code {failed_gate['exit_code']})")
        if failed_gate["stdout"].strip():
            out_snippet = failed_gate["stdout"].strip()
            if len(out_snippet) > 4000:
                out_snippet = out_snippet[:2000] + "\n... [truncated] ...\n" + out_snippet[-2000:]
            lines.append("STDOUT:")
            lines.append(f"```\n{out_snippet}\n```")
        if failed_gate["stderr"].strip():
            err_snippet = failed_gate["stderr"].strip()
            if len(err_snippet) > 4000:
                err_snippet = err_snippet[:2000] + "\n... [truncated] ...\n" + err_snippet[-2000:]
            lines.append("STDERR:")
            lines.append(f"```\n{err_snippet}\n```")
    return "\n".join(lines)


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


def print_dry_run(task: dict, cfg: dict):
    """Outputs V4 execution plan without invoking agent."""
    name = task.get("name", "unnamed-task")
    template_name = task.get("template", "None (Direct task definition)")
    variables = task.get("variables", {})
    scope = task.get("scope", cfg.get("allowed_scope", []))
    models = task.get("models", [cfg.get("default_model", "gemini-3.6-flash-medium")])
    gates = normalize_verification_gates(task, cfg.get("verify_timeout_seconds", 600))
    timeout_mins = task.get("timeout_minutes", cfg.get("timeout_minutes", 20))
    max_repairs = task.get("max_repairs", cfg.get("max_repairs", 2))

    # Pre-flight check during dry-run
    is_valid, avail_models, missing_models = validate_model_preflight(models)
    if is_valid:
        model_avail_str = f"VALID (all {len(models)} model(s) verified via agy models)"
    elif avail_models:
        model_avail_str = f"INVALID (missing: {', '.join(missing_models)})"
    else:
        model_avail_str = "UNVERIFIED (could not reach agy models)"

    print("============================================================")
    print("TITAN V4 TASK DRY RUN")
    print("============================================================")
    print(f"Task: {name}")
    print(f"Template: {template_name}")
    if variables:
        print(f"Resolved variables ({len(variables)}):")
        for k, v in variables.items():
            print(f"  - {k}: {v}")
    print(f"Scope ({len(scope)} path{'s' if len(scope) != 1 else ''}):")
    for s in scope:
        print(f"  - {s}")
    print(f"Models ({len(models)}): {', '.join(models)}")
    print(f"Model availability: {model_avail_str}")
    print("Model Sequence:")
    print(f"  - Attempt 1 (Initial): {resolve_model(models, 0, cfg.get('default_model'))}")
    for r in range(1, max_repairs + 1):
        print(f"  - Repair {r}: {resolve_model(models, r, cfg.get('default_model'))}")
    print(f"Verification Gates ({len(gates)}):")
    for i, g in enumerate(gates, 1):
        cwd_str = f" (cwd: {g['cwd']})" if g.get("cwd") and g["cwd"] != "." else ""
        print(f"  Gate {i} [{g['name']}]: `{g['command']}`{cwd_str} [timeout: {g['timeout_seconds']}s]")
    print(f"Max repairs: {max_repairs}")
    print(f"Timeout: {timeout_mins} minutes per agent turn")
    print("============================================================")


def task_command(args):
    """
    Executes the V4 autonomous implementation/verification/repair loop with
    model pre-flight validation, template resolution, and multi-stage verification gates.
    """
    cfg = load_json(CFG, DEFAULT_CONFIG)

    # 1. Load task definition
    t_path = Path(args.task_file)
    if not t_path.is_absolute():
        t_path = ROOT / t_path
    if not t_path.exists():
        raise SystemExit(f"Error: Task file not found: {t_path}")

    raw_task = load_json(t_path, None)
    if not raw_task or not isinstance(raw_task, dict):
        raise SystemExit(f"Error: Failed to parse valid JSON task from {t_path}")

    # 2. Resolve template inheritance and variable substitutions
    try:
        task = resolve_template_and_task(raw_task, base_dir=ROOT)
    except ValueError as e:
        raise SystemExit(f"Template Error: {e}")

    task_name = task.get("name") or t_path.stem
    task_scope = task.get("scope", cfg.get("allowed_scope", []))
    gates = normalize_verification_gates(task, cfg.get("verify_timeout_seconds", 600))
    max_repairs = int(task.get("max_repairs", cfg.get("max_repairs", 2)))
    models = task.get("models") or [cfg.get("default_model", "gemini-3.6-flash-medium")]
    timeout_mins = int(task.get("timeout_minutes", cfg.get("timeout_minutes", 20)))

    # 3. Dry run handling
    if args.dry_run:
        print_dry_run(task, cfg)
        return

    # 4. Live Model Pre-flight Validation
    is_valid, available_models, missing_models = validate_model_preflight(models)
    if not is_valid:
        print("\n============================================================")
        print("PRE-FLIGHT FAILURE: INVALID_MODEL_CONFIGURATION")
        print("============================================================")
        print(f"Requested models: {models}")
        print(f"Available models: {available_models if available_models else '(none discovered)'}")
        print(f"Missing models:   {missing_models}")
        print("Agent invocation blocked.")
        print("============================================================")

        state = load_json(STATE, {})
        state.update({
            "project": "TITAN",
            "status": "INVALID_MODEL_CONFIGURATION",
            "phase": "preflight_failed",
            "task": task_name,
            "current_task": task_name,
            "finished_at": datetime.now().isoformat(timespec="seconds")
        })
        save_json(STATE, state)
        raise SystemExit(1)

    # 5. Resolve prompt
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
        raise SystemExit("Error: Task definition must specify 'prompt', 'prompt_file', or a valid 'template'.")

    # Safety check for forbidden git operations in prompt
    lower_prompt = initial_prompt.lower()
    bad_ops = [op for op in FORBIDDEN_OPERATIONS if op in lower_prompt]
    if bad_ops:
        raise SystemExit(f"BLOCKED: Task prompt contains forbidden Git operation(s): {bad_ops}")

    # 6. Record baseline Git state before any agent invocation
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
    print(f"TITAN V4 ORCHESTRATOR — TASK: {task_name}")
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
        state.update({"phase": "verification", "verification_status": "RUNNING"})
        save_json(STATE, state)

        print(f"\n>>> Running Verification Pipeline ({len(gates)} gate{'s' if len(gates) != 1 else ''})...")
        v_passed, v_results, failed_gate = execute_verification_pipeline(gates, base_dir=ROOT)

        for r in v_results:
            tag = "PASS" if r["passed"] else ("TIMEOUT" if r["is_timeout"] else f"FAIL ({r['exit_code']})")
            print(f"  [{tag}] Gate: {r['name']} -> `{r['command']}` ({r['duration_seconds']}s)")

        if v_passed:
            verification_passed = True
            print(f"\n>>> ALL VERIFICATION GATES PASSED!")
            break

        # Verification Failed
        print(f"\n>>> VERIFICATION GATE FAILED: '{failed_gate['name']}' (Attempt {repair_count + 1})")
        if repair_count >= max_repairs:
            print(f"\n>>> Maximum repair attempts ({max_repairs}) exhausted.")
            break

        # Proceed to Repair Turn
        repair_count += 1
        repair_model = resolve_model(models, repair_count, cfg.get("default_model"))
        print(f"\n>>> [REPAIR TURN {repair_count}/{max_repairs}] Model Escalation: {repair_model}")

        state.update({
            "phase": f"repair_{repair_count}",
            "attempt": repair_count,
            "model": repair_model,
            "repair_count": repair_count,
            "verification_status": "FAILED"
        })
        save_json(STATE, state)

        failure_report = format_gate_failure_report(v_results, failed_gate)
        scope_str = "\n".join(f"- {s}" for s in task_scope) if task_scope else "(all non-protected files)"

        repair_prompt = (
            f"# TITAN REPAIR REQUEST (Attempt {repair_count}/{max_repairs})\n"
            f"Task: {task_name}\n"
            f"Authorized Scope:\n{scope_str}\n\n"
            f"The verification pipeline executed by the orchestrator failed at Gate '{failed_gate['name']}':\n\n"
            f"{failure_report}\n\n"
            f"Please diagnose the failure and repair ONLY files within the authorized scope:\n"
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
    for d in (LOGDIR, PROMPTDIR, RESULTDIR, TASKSDIR, TEMPLATESDIR):
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

    lower_prompt = prompt_text.lower()
    bad_ops = [op for op in FORBIDDEN_OPERATIONS if op in lower_prompt]
    if bad_ops:
        raise SystemExit(f"BLOCKED: Prompt contains forbidden operation(s): {bad_ops}")

    model = args.model or cfg.get("default_model", "gemini-3.6-flash-medium")

    before_rc, before_raw = run_shell("git status --short")
    before_map = parse_git_status(before_raw)

    timeout_mins = int(args.timeout or cfg.get("timeout_minutes", 20))

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

    after_rc, after_raw = run_shell("git status --short")
    after_map = parse_git_status(after_raw)
    delta = compute_git_delta(before_map, after_map)
    violations = check_scope_violations(delta["all_changed_files"], cfg.get("allowed_scope", []), cfg)

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
