#!/usr/bin/env python3
"""
Terminal Wrapper Render - Universal Structured Output Formatter

Transforms noisy CLI output into compact, human-readable, and AI-efficient packets.
Designed for observation-heavy commands in agent workflows (Hermes, Claude Code, Codex, etc.).
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional


class Mode(Enum):
    COMPACT = "compact"
    NORMAL = "normal"
    FULL = "full"
    RAW = "raw"


@dataclass
class RenderResult:
    output: str
    metadata: Dict[str, any]
    signals: List[str]


class CommandDetector:
    @staticmethod
    def detect(argv: List[str]) -> Optional[str]:
        if not argv:
            return None

        if argv[0] == "docker":
            if "ps" in argv:
                return "docker-ps"
            if "images" in argv:
                return "docker-images"
        if argv[0] == "git":
            if "status" in argv:
                return "git-status"
            if "diff" in argv and "--stat" in argv:
                return "git-diff-stat"
            if "log" in argv:
                return "git-log"
        if argv[0] == "kubectl":
            if "get" in argv and "pods" in argv:
                return "kubectl-get-pods"
        if argv[0] == "ps":
            return "ps-aux"
        if argv[0] in ("ss", "netstat"):
            return "ss-listen"
        if argv[0] == "systemctl":
            return "systemctl-status"
        if argv[0] == "npm" and "test" in argv:
            return "npm-test"
        if argv[0] == "pytest":
            return "pytest"
        return None


class Formatters:
    @staticmethod
    def format_docker_ps(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines or len(lines) < 2:
            return RenderResult(output="No containers.", metadata={}, signals=[])

        containers = []
        host_exposed = 0
        internal_only = 0

        for line in lines[1:]:
            parts = re.split(r'\s{2,}', line.strip())
            if len(parts) < 7:
                continue

            container_id = parts[0]
            image = parts[1]
            command = parts[2]
            created = parts[3]
            status = parts[4]
            ports = parts[5] if len(parts) > 5 else ""
            names = parts[6] if len(parts) > 6 else ""

            port_summary = ports if ports else "none"
            if "127.0.0.1:" in ports:
                host_exposed += 1
            elif "0.0.0.0:" in ports or ":::" in ports:
                host_exposed += 1
            else:
                internal_only += 1

            containers.append({
                "name": names,
                "image": image,
                "status": status,
                "ports": port_summary,
                "command": command[:30] + "..." if len(command) > 30 else command
            })

        signals = []
        if host_exposed > 0:
            signals.append(f"{host_exposed} containers expose to host")
        if internal_only > 0:
            signals.append(f"{internal_only} containers with internal-only ports")

        output = ["Docker summary"]
        output.append(f"- containers: {len(containers)}")
        output.append(f"- running: {sum(1 for c in containers if 'Up' in c['status'])}")
        output.append(f"- host-exposed: {host_exposed}")
        output.append(f"- internal-only: {internal_only}")
        output.append("")
        output.append("Containers")

        for i, c in enumerate(containers, 1):
            output.append(f"{i}. {c['name']}")
            output.append(f"   image: {c['image']}")
            output.append(f"   status: {c['status']}")
            output.append(f"   ports: {c['ports']}")
            if mode == Mode.FULL:
                output.append(f"   command: {c['command']}")
            output.append("")

        if signals:
            output.append("Signals")
            for sig in signals:
                output.append(f"- {sig}")
            output.append("")

        output.append("Metadata")
        output.append(f"- formatter: docker/docker-ps")
        output.append(f"- mode: {mode.value}")
        output.append(f"- omitted: 0")

        return RenderResult(
            output="\n".join(output),
            metadata={
                "formatter": "docker/docker-ps",
                "mode": mode.value,
                "containers": len(containers)
            },
            signals=signals
        )

    @staticmethod
    def format_git_status(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line.strip() for line in stdout.splitlines() if line.strip()]
        if not lines:
            return RenderResult(output="No changes.", metadata={}, signals=[])

        branch_info = ""
        staged = []
        modified = []
        untracked = []

        for line in lines:
            if line.startswith("On branch"):
                branch_info = line.replace("On branch", "").strip()
                continue

            if "Your branch is ahead of" in line:
                branch_info += f" (ahead)"
                continue
            if "Your branch is behind" in line:
                branch_info += f" (behind)"
                continue
            if "diverged" in line:
                branch_info += f" (diverged)"
                continue

            if len(line) >= 2 and line[0] in " MADRCU" and line[1] in "MADRCU ":
                status = line[:2]
                path = line[3:]

                if status.startswith(("M ", "A ", "D ", "R ", "C ")):
                    staged.append((status, path))
                if status[1] in "MADRC":
                    modified.append((status, path))
                if status == "??":
                    untracked.append(path)

        signals = []
        if "ahead" in branch_info:
            signals.append("Branch has unpushed commits")
        if any("D" in s for s, _ in staged) or any("D" in s for s, _ in modified):
            signals.append("Deleted files detected")
        if len(modified) > 10:
            signals.append(f"Many modified files ({len(modified)})")

        output = ["Git summary"]
        output.append(f"- branch: {branch_info}" if branch_info else "- branch: (unknown)")
        output.append(f"- staged: {len(staged)}")
        output.append(f"- modified: {len(modified)}")
        output.append(f"- untracked: {len(untracked)}")
        output.append("")

        if staged:
            output.append("Staged")
            for status, path in staged[:20]:
                output.append(f"- {status} {path}")
            if len(staged) > 20:
                output.append(f"- ({len(staged) - 20} more)")
            output.append("")

        if modified:
            output.append("Modified")
            for status, path in modified[:20]:
                output.append(f"- {status} {path}")
            if len(modified) > 20:
                output.append(f"- ({len(modified) - 20} more)")
            output.append("")

        if untracked:
            output.append("Untracked")
            for path in untracked[:20]:
                output.append(f"- {path}")
            if len(untracked) > 20:
                output.append(f"- ({len(untracked) - 20} more)")
            output.append("")

        if signals:
            output.append("Signals")
            for sig in signals:
                output.append(f"- {sig}")
            output.append("")

        output.append("Metadata")
        output.append("- formatter: git/git-status")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": "git/git-status", "mode": mode.value},
            signals=signals
        )

    @staticmethod
    def format_git_log(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines:
            return RenderResult(output="No commits.", metadata={}, signals=[])

        commits = []
        for line in lines[:20]:
            if "Author:" in line or "Date:" in line:
                continue
            if line.startswith("    "):
                commits.append(line.strip())

        output = ["Git log summary"]
        output.append(f"- recent commits: {len(commits)}")
        output.append("")
        for i, msg in enumerate(commits[:10], 1):
            output.append(f"{i}. {msg}")
        output.append("")
        output.append("Metadata")
        output.append("- formatter: git/git-log")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": "git/git-log", "mode": mode.value},
            signals=[]
        )

    @staticmethod
    def format_ps_aux(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines or len(lines) < 2:
            return RenderResult(output="No processes.", metadata={}, signals=[])

        processes = []
        for line in lines[1:]:
            parts = line.split(None, 10)
            if len(parts) >= 11:
                processes.append({
                    "user": parts[0],
                    "pid": parts[1],
                    "cpu": parts[2],
                    "mem": parts[3],
                    "comm": parts[10][:40]
                })

        high_cpu = [p for p in processes if float(p["cpu"]) > 50.0]
        top_cpu = max(processes, key=lambda p: float(p["cpu"])) if processes else None
        top_mem = max(processes, key=lambda p: float(p["mem"])) if processes else None

        output = ["Process summary"]
        output.append(f"- total: {len(processes)}")
        output.append(f"- high CPU (>50%): {len(high_cpu)}")
        output.append("")

        if top_cpu:
            output.append(f"Top CPU: {top_cpu['cpu']}%")
            output.append(f"  pid: {top_cpu['pid']}")
            output.append(f"  user: {top_cpu['user']}")
            output.append(f"  comm: {top_cpu['comm']}")
            output.append("")

        if top_mem and top_mem != top_cpu:
            output.append(f"Top memory: {top_mem['mem']}%")
            output.append(f"  pid: {top_mem['pid']}")
            output.append(f"  user: {top_mem['user']}")
            output.append(f"  comm: {top_mem['comm']}")
            output.append("")

        signals = []
        if high_cpu:
            signals.append(f"{len(high_cpu)} high-CPU processes detected")

        if signals:
            output.append("Signals")
            for sig in signals:
                output.append(f"- {sig}")
            output.append("")

        output.append("Metadata")
        output.append("- formatter: system/ps-aux")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": "system/ps-aux", "mode": mode.value},
            signals=signals
        )

    @staticmethod
    def format_ss_listen(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines or len(lines) < 2:
            return RenderResult(output="No listening sockets.", metadata={}, signals=[])

        sockets = []
        public_binds = 0
        localhost_binds = 0

        for line in lines[1:]:
            parts = line.split()
            if len(parts) < 6:
                continue

            proto = parts[0]
            state = parts[1]
            local = parts[4]
            process = parts[-1] if len(parts) > 5 else ""

            if state == "LISTEN":
                bind_type = "internal"
                if local.startswith("0.0.0.0:") or local.startswith("[::]:"):
                    bind_type = "public"
                    public_binds += 1
                elif local.startswith("127.0.0.1:") or local.startswith("[::1]:"):
                    bind_type = "localhost"
                    localhost_binds += 1

                sockets.append({
                    "proto": proto,
                    "local": local,
                    "process": process,
                    "bind_type": bind_type
                })

        signals = []
        if public_binds > 0:
            signals.append(f"{public_binds} public network binds detected")
        if localhost_binds > 0:
            signals.append(f"{localhost_binds} localhost binds")

        output = ["Listening sockets"]
        output.append(f"- total: {len(sockets)}")
        output.append(f"- public: {public_binds}")
        output.append(f"- localhost: {localhost_binds}")
        output.append("")

        output.append("Top listeners")
        for i, s in enumerate(sockets[:15], 1):
            output.append(f"{i}. {s['local']}")
            output.append(f"   proto: {s['proto']}")
            output.append(f"   process: {s['process']}")
            output.append(f"   type: {s['bind_type']}")
            output.append("")

        if signals:
            output.append("Signals")
            for sig in signals:
                output.append(f"- {sig}")
            output.append("")

        output.append("Metadata")
        output.append("- formatter: system/ss-listen")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": "system/ss-listen", "mode": mode.value},
            signals=signals
        )

    @staticmethod
    def format_systemctl_status(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines:
            return RenderResult(output="Service status unavailable.", metadata={}, signals=[])

        unit = ""
        active = ""
        substate = ""
        since = ""
        main_pid = ""
        docs = ""

        for line in lines:
            if "Loaded:" in line:
                match = re.search(r'Loaded:.*\(([^)]+)\)', line)
                if match:
                    unit = match.group(1)
            if "Active:" in line:
                match = re.search(r'Active: (\S+)\s+\(([^)]+)\)', line)
                if match:
                    active = match.group(1)
                    substate = match.group(2)
            if "Since:" in line:
                since = line.split("Since:")[-1].strip()
            if "Main PID:" in line:
                match = re.search(r'Main PID: (\S+)', line)
                if match:
                    main_pid = match.group(1)
            if "Docs:" in line:
                docs = line.split("Docs:")[-1].strip()

        signals = []
        if active == "inactive":
            signals.append("Service is inactive")
        if active == "failed":
            signals.append("Service failed")
        if "dead" in substate.lower():
            signals.append("Service dead")

        output = ["Service summary"]
        output.append(f"- unit: {unit}")
        output.append(f"- active: {active}")
        output.append(f"- substate: {substate}")
        if main_pid:
            output.append(f"- main pid: {main_pid}")
        if since:
            output.append(f"- since: {since}")
        output.append("")

        if signals:
            output.append("Signals")
            for sig in signals:
                output.append(f"- {sig}")
            output.append("")

        if docs:
            output.append("Docs")
            output.append(f"- {docs}")
            output.append("")

        output.append("Metadata")
        output.append("- formatter: system/systemctl-status")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": "system/systemctl-status", "mode": mode.value},
            signals=signals
        )

    @staticmethod
    def format_kubectl_get_pods(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines or len(lines) < 2:
            return RenderResult(output="No pods found.", metadata={}, signals=[])

        pods = []
        namespaces = set()
        healthy = 0
        restarting = 0
        pending = 0
        failed = 0

        for line in lines[1:]:
            parts = line.split()
            if len(parts) >= 5:
                namespace = parts[0]
                name = parts[1]
                ready = parts[2]
                status = parts[3]
                restarts = int(parts[4]) if parts[4].isdigit() else 0

                namespaces.add(namespace)

                pod_status = status.lower()
                if pod_status == "running" or pod_status == "succeeded":
                    healthy += 1
                if "crashloopbackoff" in pod_status:
                    failed += 1
                if "pending" in pod_status:
                    pending += 1
                if restarts > 0:
                    restarting += 1

                pods.append({
                    "namespace": namespace,
                    "name": name,
                    "status": status,
                    "restarts": restarts,
                    "ready": ready
                })

        signals = []
        if failed > 0:
            signals.append(f"{failed} failed pods")
        if pending > 0:
            signals.append(f"{pending} pending pods")
        if restarting > 0:
            signals.append(f"{restarting} pods have restarts")

        output = ["Kubernetes pod summary"]
        output.append(f"- namespaces: {len(namespaces)}")
        output.append(f"- pods: {len(pods)}")
        output.append(f"- healthy: {healthy}")
        output.append(f"- restarting: {restarting}")
        output.append(f"- pending: {pending}")
        output.append(f"- failed: {failed}")
        output.append("")

        if signals or failed or pending:
            output.append("Notable pods")
            for pod in pods[:20]:
                if pod["status"].lower() in ("crashloopbackoff", "pending", "error"):
                    output.append(f"- {pod['namespace']}/{pod['name']}")
                    output.append(f"  status: {pod['status']}")
                    output.append(f"  restarts: {pod['restarts']}")
                    output.append(f"  ready: {pod['ready']}")
            output.append("")

        output.append("Metadata")
        output.append("- formatter: kubernetes/kubectl-get-pods")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={
                "formatter": "kubernetes/kubectl-get-pods",
                "mode": mode.value,
                "pods": len(pods)
            },
            signals=signals
        )

    @staticmethod
    def format_docker_images(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines or len(lines) < 2:
            return RenderResult(output="No images.", metadata={}, signals=[])

        images = []
        dangling = 0

        for line in lines[1:]:
            parts = line.split(None, 6)
            if len(parts) >= 7:
                repo = parts[0]
                tag = parts[1]
                image_id = parts[2]
                created = parts[3]
                size = parts[4]

                if "<none>" in repo and "<none>" in tag:
                    dangling += 1

                images.append({
                    "repository": repo,
                    "tag": tag,
                    "id": image_id,
                    "created": created,
                    "size": size
                })

        signals = []
        if dangling > 0:
            signals.append(f"{dangling} dangling images detected")

        output = ["Docker image summary"]
        output.append(f"- images: {len(images)}")
        output.append(f"- dangling: {dangling}")
        output.append("")

        output.append("Images")
        for i, img in enumerate(images[:20], 1):
            name = f"{img['repository']}:{img['tag']}"
            output.append(f"{i}. {name}")
            output.append(f"   id: {img['id']}")
            output.append(f"   size: {img['size']}")
            output.append(f"   created: {img['created']}")
            output.append("")

        if signals:
            output.append("Signals")
            for sig in signals:
                output.append(f"- {sig}")
            output.append("")

        output.append("Metadata")
        output.append("- formatter: docker/docker-images")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": "docker/docker-images", "mode": mode.value},
            signals=signals
        )

    @staticmethod
    def format_git_diff_stat(stdout: str, mode: Mode = Mode.COMPACT) -> RenderResult:
        lines = [line for line in stdout.splitlines() if line.strip()]
        if not lines:
            return RenderResult(output="No changes.", metadata={}, signals=[])

        files = []
        total_insertions = 0
        total_deletions = 0

        for line in lines:
            if line.strip() == "" or "|" not in line:
                continue

            parts = line.split("|")
            if len(parts) >= 2:
                file_path = parts[0].strip()
                changes = parts[1].strip()

                insertions = 0
                deletions = 0

                nums = re.findall(r'(\d+)(?: insertion)?', changes)
                if nums:
                    insertions = int(nums[0]) if len(nums) > 0 else 0

                nums = re.findall(r'(\d+)(?: deletion)?', changes)
                if nums:
                    deletions = int(nums[0]) if len(nums) > 0 else 0

                total_insertions += insertions
                total_deletions += deletions

                files.append({
                    "file": file_path,
                    "insertions": insertions,
                    "deletions": deletions
                })

        signals = []
        if total_insertions + total_deletions > 1000:
            signals.append("Large diff detected")
        if len(files) > 20:
            signals.append("Many files changed")

        output = ["Diff summary"]
        output.append(f"- files changed: {len(files)}")
        output.append(f"- insertions: {total_insertions}")
        output.append(f"- deletions: {total_deletions}")
        output.append("")

        output.append("Top changed files")
        for f in sorted(files, key=lambda x: -(x["insertions"] + x["deletions"]))[:15]:
            output.append(f"- {f['file']}")
            output.append(f"  +{f['insertions']} -{f['deletions']}")
            output.append("")

        if signals:
            output.append("Signals")
            for sig in signals:
                output.append(f"- {sig}")
            output.append("")

        output.append("Metadata")
        output.append("- formatter: git/git-diff-stat")
        output.append(f"- mode: {mode.value}")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": "git/git-diff-stat", "mode": mode.value},
            signals=signals
        )


class TerminalWrapper:
    def __init__(self, mode: Mode = Mode.COMPACT):
        self.mode = mode
        self.detector = CommandDetector()
        self.formatters = {
            "docker-ps": Formatters.format_docker_ps,
            "git-status": Formatters.format_git_status,
            "git-log": Formatters.format_git_log,
            "git-diff-stat": Formatters.format_git_diff_stat,
            "ps-aux": Formatters.format_ps_aux,
            "ss-listen": Formatters.format_ss_listen,
            "systemctl-status": Formatters.format_systemctl_status,
            "kubectl-get-pods": Formatters.format_kubectl_get_pods,
            "docker-images": Formatters.format_docker_images,
        }

    def render(self, stdout: str, formatter_key: str) -> RenderResult:
        formatter = self.formatters.get(formatter_key)
        if not formatter:
            return self.fallback(stdout, formatter_key)

        return formatter(stdout, self.mode)

    def fallback(self, stdout: str, reason: str) -> RenderResult:
        lines = stdout.splitlines()
        lines_to_show = lines[:100]

        output = ["Formatter fallback"]
        output.append(f"- formatter: {reason}")
        output.append(f"- reason: unknown or unimplemented")
        output.append(f"- mode: bounded-raw")
        output.append("")
        output.extend(lines_to_show)

        if len(lines) > 100:
            output.append("")
            output.append(f"({len(lines) - 100} more lines omitted)")

        return RenderResult(
            output="\n".join(output),
            metadata={"formatter": reason, "mode": "fallback"},
            signals=[]
        )

    def execute_and_render(self, argv: List[str]) -> RenderResult:
        formatter_key = self.detector.detect(argv)

        if not formatter_key:
            return self.fallback("", "unknown-command")

        try:
            result = subprocess.run(
                argv,
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode != 0:
                return RenderResult(
                    output=f"Command failed: {' '.join(argv)}\nExit code: {result.returncode}\n{result.stderr}",
                    metadata={"formatter": formatter_key, "mode": "error"},
                    signals=["command-failed"]
                )

            return self.render(result.stdout, formatter_key)

        except subprocess.TimeoutExpired:
            return RenderResult(
                output=f"Command timed out: {' '.join(argv)}",
                metadata={"formatter": formatter_key, "mode": "timeout"},
                signals=["timeout"]
            )
        except Exception as e:
            return RenderResult(
                output=f"Error executing command: {e}",
                metadata={"formatter": formatter_key, "mode": "error"},
                signals=["error"]
            )


def main():
    parser = argparse.ArgumentParser(description="Terminal Wrapper Render - Structured output formatter")
    parser.add_argument("--mode", choices=["compact", "normal", "full", "raw"], default="compact", help="Output mode")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Command to render")

    args = parser.parse_args()
    mode = Mode(args.mode)

    if not args.command:
        parser.print_help()
        sys.exit(1)

    wrapper = TerminalWrapper(mode=mode)
    result = wrapper.execute_and_render(args.command)

    print(result.output)


if __name__ == "__main__":
    main()