#!/bin/bash

#POLICIES="base elasticcontainer"
#APPS="bwa fastqc samtools_sort samtools_index gatk_baserecal_spark star trimmomatic"
POLICIES="base elasticcontainer autothrottle"
APPS="star"
for POLICY in $POLICIES; do
  for APP in $APPS; do
    # python3 driver/corr-by_policies.py --app ${APP} --policy ${POLICY}
    python3 driver/contention.py --app ${APP} --policy ${POLICY}
  done
done
