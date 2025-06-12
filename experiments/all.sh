#!/bin/bash

#POLICIES="base elasticcontainer"
#APPS="bwa fastqc samtools_sort samtools_index gatk_baserecal_spark star trimmomatic"
POLICIES="autothrottle" # base elasticcontainer showar autothrottle"
APPS="bwa"
for POLICY in $POLICIES; do
  for APP in $APPS; do
    python3 driver/default_policies.py --app ${APP} --policy ${POLICY}
    # python3 driver/corr-by_policies.py --app ${APP} --policy ${POLICY}
    # python3 driver/contention.py --app ${APP} --policy ${POLICY}
    # python3 driver/deeplearning.py --app ${APP} --policy ${POLICY}
    # python3 driver/deeplearning_varycpus.py --app ${APP} --policy base
  done
done
