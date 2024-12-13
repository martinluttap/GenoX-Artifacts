#!/usr/bin/env python3

from typing import Any, Callable, Dict, List, Set, Tuple

import argparse
import datetime
import os
from pathlib import Path
import itertools
import subprocess
import time

from utils import (
    TOP_DIR,
    APPS,
    POLICIES,
    START_RUN,
    END_RUN,
    kill_associated_processes,
    run_agent,
    run_resnet18,
    run_stress,
    run_exp_prep,
    run_exp_cleanup,
    run_resmon,
)

"""
Run ResNet experiment.
"""

parser = argparse.ArgumentParser(
    prog="deeplearning",
    description=f"Script for ResNet experiment.",
)

parser.add_argument("--app", type=str, choices=APPS, help="Application to run")
parser.add_argument("--policy", type=str, choices=POLICIES, help="Policy to run")

args = parser.parse_args()
args.policy = "base"


def main():
    print(f"{TOP_DIR}, running program: {args.app}")

    RUNS = [i for i in range(START_RUN, END_RUN)]
    # STRESS_NUMCORES = [ 95, 94, 92, 80, 64, 32, 0 ] # 0 will fail
    CPUS = [8, 16]  # 0 will fail

    for RUN, CPU in list(itertools.product(RUNS, CPUS)):
        try:
            assert args.app, "Application not provided"
            assert args.policy, "Policy not provided"

            WORKFLOW = f"/home/cc/2024-biosys-ec/experiments/nf_scripts/{args.app}.nf"
            INPUT_CONFIG = (
                f"/home/cc/2024-biosys-ec/experiments/configs/{args.app}.config"
            )
            PATH_CONTROLLER = (
                f"/home/cc/2024-biosys-ec/elasticcontainer/controller/controller.go"
            )
            APP = args.app
            POLICY = args.policy

            print(
                f"============ Timestamp:{datetime.datetime.now()},app={APP},policy={POLICY}, RUN={RUN}  ============"
            )

            LABEL = f"epoch10_batch512_cpus{CPU}-{RUN}-{POLICY}-{APP}"
            OUT_LOG = f"{LABEL}.log"

            # Run prep
            kill_associated_processes()
            run_exp_prep(INPUT_CONFIG, LABEL, WORKFLOW)

            # Run Agent
            # all_agent_ps = run_agent(LABEL, POLICY)
            all_agent_ps = []

            # Run Resmon
            resmon_ps = run_resmon(LABEL)
            # Run Resnet18
            resnet_ps = run_resnet18(LABEL, CPU)

            while resnet_ps.poll() is None:
                print(f"{resnet_ps.stdout} Running ...")
                time.sleep(1)

            print("ResNet process finished!")
            # while agent_ps.poll() is None:
            for ps in all_agent_ps:
                subprocess.check_output(f"sudo kill -9 {ps.pid}".split())
                print(f"Agent PID {ps.pid} killed!")
                try:
                    subprocess.check_output(f"sudo pkill -TERM -P {ps.pid}".split())
                    print(f"Child processes of PPID {ps.pid} killed!")
                except Exception as e:
                    print(e)

            # while resmon_ps.poll() is None:
            subprocess.check_output(f"sudo kill -9 {resmon_ps.pid}".split())
            print("Resmon killed!")

            # Cleanup
            run_exp_cleanup(LABEL)

            kill_associated_processes()

        except Exception as e:
            print(f"Error: {e}")
            # parser.print_help()

        time.sleep(3)


if __name__ == "__main__":
    main()
