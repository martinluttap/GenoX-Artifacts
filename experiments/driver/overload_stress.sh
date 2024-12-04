#!/bin/bash

ps aux | grep "stress --cpu" | awk '{print $2}' | xargs sudo kill -9

CORE_AVAIL=2
CORE_REQ=96
CORE_ALLOC=-1

sed -e "s|num_threads =.*|num_threads = ${CORE_REQ}|" -i /home/cc/2024-biosys-ec/experiments/configs/bwa.config 
sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches ; sudo swapoff -a && sudo swapon -a

nproc=$(nproc)
cd /sys/fs/cgroup/cpuset/docker ; echo "0-$((nproc-1))" > cpuset.cpus 
cd /sys/fs/cgroup/cpuset/docker ; echo 0 > cpuset.cpu_exclusive 
# cd /sys/fs/cgroup/cpu/docker ; echo $((CORE_ALLOC*100000)) > cpu.cfs_quota_us
cd /sys/fs/cgroup/cpu/docker ; echo -1 > cpu.cfs_quota_us

echo "num_threads: $(cat /home/cc/2024-biosys-ec/experiments/configs/bwa.config | grep num_threads)"
echo "/sys/fs/cgroup/cpu/docker/cpu.cfs_quota_us: $(cat /sys/fs/cgroup/cpu/docker/cpu.cfs_quota_us)"
echo "/sys/fs/cgroup/cpuset/docker/cpuset.cpus: $(cat /sys/fs/cgroup/cpuset/docker/cpuset.cpus)"
echo "/sys/fs/cgroup/cpuset/docker/cpuset.cpu_exclusive: $(cat /sys/fs/cgroup/cpuset/docker/cpuset.cpu_exclusive)"

stress --cpu $(($(nproc) - $CORE_AVAIL))