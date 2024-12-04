#!/bin/bash

sed -e "s|num_threads =.*|num_threads = 96|" -i /home/cc/2024-biosys-ec/experiments/configs/bwa.config 
sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches ; sudo swapoff -a && sudo swapon -a
cd /sys/fs/cgroup/cpu/docker ; echo 100000 > cpu.cfs_quota_us
cd /sys/fs/cgroup/cpuset/docker ; echo 0 > cpuset.cpus 
cd /sys/fs/cgroup/cpuset/docker ; echo 1 > cpuset.cpu_exclusive 

echo "num_threads: $(cat /home/cc/2024-biosys-ec/experiments/configs/bwa.config | grep num_threads)"
echo "/sys/fs/cgroup/cpu/docker/cpu.cfs_quota_us: $(cat /sys/fs/cgroup/cpu/docker/cpu.cfs_quota_us)"
echo "/sys/fs/cgroup/cpuset/docker/cpuset.cpus: $(cat /sys/fs/cgroup/cpuset/docker/cpuset.cpus)"
echo "/sys/fs/cgroup/cpuset/docker/cpuset.cpu_exclusive: $(cat /sys/fs/cgroup/cpuset/docker/cpuset.cpu_exclusive)"