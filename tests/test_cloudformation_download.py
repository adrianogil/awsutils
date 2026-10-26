"""Offline shell integration checks; never use real AWS credentials or APIs."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "aws_cloudformation.sh"
SHELLS = [shell for shell in ("bash", "zsh") if shutil.which(shell)]


class DownloadStacksTests(unittest.TestCase):
    def run_command(self, shell, root, args=(), payload="[]", exit_code=0):
        fake_aws = root / "aws"
        fake_aws.write_text(
            "#!/bin/sh\n"
            'printf "%s\\n" "$@" > "$AWS_TEST_ARGS"\n'
            'printf "%s\\n" "$AWS_TEST_PAYLOAD"\n'
            'exit "$AWS_TEST_EXIT"\n'
        )
        fake_aws.chmod(0o755)
        return subprocess.run(
            [shell, "-c", 'source "$1"; shift; aws-cloudformation-download-stacks "$@"',
             "test", str(SOURCE), *args],
            cwd=root,
            env={**os.environ, "PATH": f"{root}:/usr/bin:/bin",
                 "AWS_TEST_ARGS": str(root / "args"),
                 "AWS_TEST_PAYLOAD": payload, "AWS_TEST_EXIT": str(exit_code)},
            capture_output=True, text=True,
        )

    def test_default_export_and_empty_account(self):
        for shell in SHELLS:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                result = self.run_command(shell, root)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads((root / "cloudformation-stacks.json").read_text()), [])
                args = (root / "args").read_text().splitlines()
                self.assertEqual(args[:2], ["cloudformation", "describe-stacks"])
                self.assertEqual(args[-2:], ["--output", "json"])
                self.assertNotIn("--no-paginate", args)
                self.assertNotIn("--max-items", args)
                self.assertEqual(list(root.glob("*.tmp.*")), [])

    def test_custom_destination_and_scope(self):
        for shell in SHELLS:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                payload = json.dumps([{"Name": "app", "Tags": [{"Key": "Owner", "Value": "José"}]}])
                result = self.run_command(
                    shell, root, ["my stacks.json", "--profile", "my profile", "--region", "us-west-2"],
                    payload=payload,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads((root / "my stacks.json").read_text()), json.loads(payload))
                args = (root / "args").read_text().splitlines()
                self.assertEqual(args[2:6], ["--profile", "my profile", "--region", "us-west-2"])

    def test_failed_download_preserves_destination_and_exit_status(self):
        for shell in SHELLS:
            for existing in (False, True):
                with self.subTest(shell=shell, existing=existing), tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    destination = root / "stacks.json"
                    if existing:
                        destination.write_text("previous export")
                    result = self.run_command(shell, root, ["stacks.json"], payload="partial output", exit_code=42)
                    self.assertEqual(result.returncode, 42)
                    if existing:
                        self.assertEqual(destination.read_text(), "previous export")
                    else:
                        self.assertFalse(destination.exists())
                    self.assertEqual(list(root.glob("*.tmp.*")), [])
                    self.assertNotIn("Saved", result.stdout)

    def test_invalid_arguments_do_not_call_aws(self):
        for shell in SHELLS:
            for args in (["--profile"], ["--region", "--profile", "prod"],
                         ["--no-paginate"], ["--max-items", "1"], [""], ["."],
                         ["missing/stacks.json"]):
                with self.subTest(shell=shell, args=args), tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    result = self.run_command(shell, root, args)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertFalse((root / "args").exists())

    def test_help_does_not_call_aws(self):
        for shell in SHELLS:
            for flag in ("--help", "-h"):
                with self.subTest(shell=shell, flag=flag), tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    result = self.run_command(shell, root, [flag])
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn("Usage:", result.stdout)
                    self.assertFalse((root / "args").exists())


if __name__ == "__main__":
    unittest.main()
