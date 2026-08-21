import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from titan_agent.cli import (
    check_scope_violations,
    compute_git_delta,
    execute_verification_pipeline,
    format_gate_failure_report,
    normalize_verification_gates,
    resolve_model,
    resolve_template_and_task,
    validate_model_preflight,
)


class TestTitanAgentV4Foundation(unittest.TestCase):

    def test_01_valid_model_passes_preflight(self):
        available = ["gemini-3.6-flash-medium", "gemini-3.6-flash-high", "claude-sonnet-4-6"]
        requested = ["gemini-3.6-flash-medium", "gemini-3.6-flash-high"]
        is_valid, avail, missing = validate_model_preflight(requested, available)
        self.assertTrue(is_valid)
        self.assertEqual(missing, [])
        self.assertEqual(avail, available)

    def test_02_invalid_model_blocks_execution(self):
        available = ["gemini-3.6-flash-medium", "claude-sonnet-4-6"]
        requested = ["gemini-3.6-flash-medium", "non-existent-model-xyz"]
        is_valid, avail, missing = validate_model_preflight(requested, available)
        self.assertFalse(is_valid)
        self.assertEqual(missing, ["non-existent-model-xyz"])

    def test_03_template_substitution(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmppath = Path(tmpdir)
            tpl_file = tmppath / "feature_tpl.json"
            tpl_content = {
                "name": "reader-feature-tpl",
                "variables": ["phase", "feature", "scope", "requirements"],
                "prompt": "Implement Phase {{phase}}: {{feature}}.\nScope: {{scope}}\nReqs: {{requirements}}",
                "verification_gates": [
                    {"name": "Analyze", "command": "dart analyze"}
                ]
            }
            tpl_file.write_text(json.dumps(tpl_content), encoding="utf-8")

            task_def = {
                "name": "task-6d2",
                "template": str(tpl_file),
                "variables": {
                    "phase": "6D-2",
                    "feature": "Native Outline",
                    "scope": "project_titan/apps/titan_reader",
                    "requirements": "Tree navigation widget"
                }
            }

            resolved = resolve_template_and_task(task_def, base_dir=tmppath)
            self.assertEqual(resolved["name"], "task-6d2")
            self.assertIn("Implement Phase 6D-2: Native Outline.", resolved["prompt"])
            self.assertIn("Scope: project_titan/apps/titan_reader", resolved["prompt"])
            self.assertIn("Reqs: Tree navigation widget", resolved["prompt"])
            self.assertEqual(len(resolved["verification_gates"]), 1)

    def test_04_missing_template_variable_detection(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmppath = Path(tmpdir)
            tpl_file = tmppath / "strict_tpl.json"
            tpl_content = {
                "name": "strict-tpl",
                "variables": ["phase", "feature", "mandatory_flag"],
                "prompt": "Phase {{phase}}: {{feature}} - {{mandatory_flag}}"
            }
            tpl_file.write_text(json.dumps(tpl_content), encoding="utf-8")

            task_def = {
                "name": "task-incomplete",
                "template": str(tpl_file),
                "variables": {
                    "phase": "6D-2",
                    "feature": "Native Outline"
                }
            }

            with self.assertRaises(ValueError) as ctx:
                resolve_template_and_task(task_def, base_dir=tmppath)
            self.assertIn("Missing required template variable(s): mandatory_flag", str(ctx.exception))

    def test_05_direct_prompt_backward_compatibility(self):
        task_def = {
            "name": "v3-task-direct",
            "prompt": "Direct prompt instructions without template",
            "verify": ["echo step1", "echo step2"],
            "max_repairs": 2
        }
        resolved = resolve_template_and_task(task_def)
        self.assertEqual(resolved["prompt"], "Direct prompt instructions without template")
        gates = normalize_verification_gates(resolved)
        self.assertEqual(len(gates), 2)
        self.assertEqual(gates[0]["name"], "Check #1")
        self.assertEqual(gates[0]["command"], "echo step1")

    def test_06_prompt_file_backward_compatibility(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmppath = Path(tmpdir)
            p_file = tmppath / "prompt.md"
            p_file.write_text("# Markdown Prompt Content", encoding="utf-8")

            task_def = {
                "name": "v3-task-file",
                "prompt_file": str(p_file),
                "verification_gates": [
                    {"name": "Gate A", "command": "python -c \"print('A')\""}
                ]
            }
            resolved = resolve_template_and_task(task_def, base_dir=tmppath)
            self.assertEqual(resolved["prompt_file"], str(p_file))
            gates = normalize_verification_gates(resolved)
            self.assertEqual(len(gates), 1)
            self.assertEqual(gates[0]["name"], "Gate A")

    def test_07_multi_gate_all_pass(self):
        gates = [
            {"name": "Gate 1", "command": "py -c \"print('Gate 1 passed')\"", "cwd": ".", "timeout_seconds": 10},
            {"name": "Gate 2", "command": "py -c \"print('Gate 2 passed')\"", "cwd": ".", "timeout_seconds": 10},
            {"name": "Gate 3", "command": "py -c \"print('Gate 3 passed')\"", "cwd": ".", "timeout_seconds": 10}
        ]
        all_passed, results, failed_gate = execute_verification_pipeline(gates)
        self.assertTrue(all_passed)
        self.assertIsNone(failed_gate)
        self.assertEqual(len(results), 3)
        for r in results:
            self.assertEqual(r["status"], "PASS")

    def test_08_first_gate_failure_stops_pipeline(self):
        gates = [
            {"name": "Gate 1 Fail", "command": "py -c \"import sys; sys.exit(1)\"", "cwd": ".", "timeout_seconds": 10},
            {"name": "Gate 2 Never Reached", "command": "py -c \"print('Unreachable')\"", "cwd": ".", "timeout_seconds": 10}
        ]
        all_passed, results, failed_gate = execute_verification_pipeline(gates)
        self.assertFalse(all_passed)
        self.assertIsNotNone(failed_gate)
        self.assertEqual(failed_gate["name"], "Gate 1 Fail")
        self.assertEqual(failed_gate["status"], "FAIL")
        # Ensure gate 2 was never executed
        self.assertEqual(len(results), 1)

    def test_09_gate_timeout(self):
        gates = [
            {"name": "Gate Slow", "command": "py -c \"import time; time.sleep(5)\"", "cwd": ".", "timeout_seconds": 1}
        ]
        all_passed, results, failed_gate = execute_verification_pipeline(gates)
        self.assertFalse(all_passed)
        self.assertIsNotNone(failed_gate)
        self.assertEqual(failed_gate["status"], "TIMEOUT")
        self.assertEqual(failed_gate["exit_code"], 124)

    def test_10_bounded_repair_after_gate_failure(self):
        models = ["model-a", "model-b", "model-c"]
        self.assertEqual(resolve_model(models, 0), "model-a")  # Initial
        self.assertEqual(resolve_model(models, 1), "model-a")  # Repair 1 (same model)
        self.assertEqual(resolve_model(models, 2), "model-b")  # Repair 2 (escalate)
        self.assertEqual(resolve_model(models, 3), "model-c")  # Repair 3 (escalate)


if __name__ == "__main__":
    unittest.main()
