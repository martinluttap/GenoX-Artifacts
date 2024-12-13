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
    run_nextflow,
    run_stress,
    run_exp_prep,
    run_exp_cleanup,
    run_resmon,
)

"""
Script for gathering evidence of correlated metrics by policy.
"""

parser = argparse.ArgumentParser(
    prog="corr-by_policies",
    description=f"Scripts for gathering evidence of correlated metrics by policy.",
    # epilog='Text at the bottom of help'
)

parser.add_argument("--app", type=str, choices=APPS, help="Application to run")
parser.add_argument("--policy", type=str, choices=POLICIES, help="Policy to run")

args = parser.parse_args()


def main():
    print(f"{TOP_DIR}, running program: {args.app}")

    RUNS = [i for i in range(START_RUN, END_RUN)]
    # STRESS_NUMCORES = [ 95, 94, 92, 80, 64, 32, 0 ] # 0 will fail
    STRESS_NUMCORES = [0]  # 0 will fail

    for RUN, NUMCORE in list(itertools.product(RUNS, STRESS_NUMCORES)):
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

            LABEL = f"scale_freq_0.02s-{NUMCORE}-{RUN}-{POLICY}-{APP}"
            OUT_LOG = f"{LABEL}.log"

            # Run prep
            kill_associated_processes()
            run_exp_prep(INPUT_CONFIG, LABEL, WORKFLOW)

            # Run Agent
            all_agent_ps = run_agent(LABEL, POLICY)

            # Run Resmon
            resmon_ps = run_resmon(LABEL)
            # Run Nextflow
            nextflow_ps = run_nextflow(INPUT_CONFIG, LABEL, OUT_LOG)
            # Run stressor
            stress_ps = run_stress(NUMCORE)

            while nextflow_ps.poll() is None:
                for line in nextflow_ps.stdout:
                    print(line)
                time.sleep(1)

            print("Nextflow process finished!")
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
