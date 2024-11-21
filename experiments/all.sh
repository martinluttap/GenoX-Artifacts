#!/bin/bash

#POLICIES="base elasticcontainer"
#APPS="bwa fastqc samtools_sort samtools_index gatk_baserecal_spark star trimmomatic"
POLICIES="elasticcontainer"
APPS="bwa"
for POLICY in $POLICIES; do
  for APP in $APPS; do
    python3 driver/corr-by_policies.py --app ${APP} --policy ${POLICY}
  done
done
