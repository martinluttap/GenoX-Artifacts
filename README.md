# GenoX Artifacts

This repository contains artefacts for **GenoX [HiPC 2026]**, a thread-based CPU allocation system for genomics workflows. 

----

# Overview

The tree structure below shows the **most important folders** used to reproduce GenoX's experiments.  

```
├── README.md.
├── experiments
│   ├── all.sh      # one-shot experiment script. Call python drivers.
│   ├── configs     # Nextflow config files.
│   ├── driver      # Python drivers to prepare environment, run NF workflows, execute GenoX/baselines, and cleanup.  
│   ├── nf_scripts   # Nextflow files for workflows (DNA-Seq, RNA-Seq, and per-app experiments).    
│   │   ├── tools       # Modularized Nextflow Processes. 
├── genox       # GenoX agent.
└── sota        # Baseline agents.  
    ├── autopilot
    ├── autothrottle
    └── showar
```

----
# Requirements & Setup

TBD.

----
# How to run

TBD. 