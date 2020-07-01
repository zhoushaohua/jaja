#/bin/bash

sysctl_params=(
    "vm.swappiness"
    "vm.dirty_background_ratio"
    "vm.dirty_ratio"
    "vm.dirty_expire_centisecs"
    "vm.dirty_writeback_centisecs"
    "vm.nr_hugepages"
    "vm.hugetlb_shm_group"
    "kernel.shmmax"
    "kernel.shmall"
    "kernel.shmmni"
    "kernel.sem"
    )
echo 'The script will set kernel parameters at runtime and configuration of pam_limits module below. Your previous configurations will be overridden:'
echo '########### Kernel parameters at runtime to be set #############'
for p in ${sysctl_params[@]}; do
    echo $p
done
echo '########### Fields of pam_limits module to be set #############'
echo "oracle soft memlock"
echo "oracle hard memlock"
echo "oracle hard nofile"
while true; do
    read -p "Will you continue? [Y/N]" yn
    case $yn in
        [Yy] )
            break
            ;;
        [Nn] )
            exit 
            break
            ;;
    esac
done

function commentExisting {
    params=("$@")
    params=("${params[@]:1}")
    confile="$1"
    for p in ${params[@]}; do
        sed -Ei 's/'$p'/# &/g' $confile
    done
}


currentTimestamp=`date +%y-%m-%d-%H:%M:%S`
echo "Backing up configuration files."

backup="/etc/sysctl.conf.$currentTimestamp.bak"
cp "/etc/sysctl.conf" $backup 
backup="/etc/security/limits.conf.$currentTimestamp.bak"
cp "/etc/security/limits.conf" $backup 
backup="/boot/grub/grub.conf.$currentTimestamp.bak"
cp "/boot/grub/grub.conf" $backup 

sysctl_check="/etc/sysctl.conf"
limits_check="/etc/security/limits.conf"
sysctl_conf="/etc/sysctl.conf"
limits_conf="/etc/security/limits.conf"


sysctl_params=(
    "vm.swappiness\s*="
    "vm.dirty_background_ratio\s*="
    "vm.dirty_ratio\s*="
    "vm.dirty_expire_centisecs\s*="
    "vm.dirty_writeback_centisecs\s*="
    "vm.nr_hugepages\s*="
    "vm.hugetlb_shm_group\s*="
    "kernel.shmmax\s*="
    "kernel.shmall\s*="
    "kernel.shmmni\s*="
    "kernel.sem\s*="
    )

limits_params=(
    "oracle\s+soft\s+memlock\s+"
    "oracle\s+hard\s+memlock\s+"
    "oracle\s+hard\s+nofile\s+"
    )
commentExisting $sysctl_check ${sysctl_params[@]}
commentExisting $limits_check ${limits_params[@]}

# HugePages
hugepagesize=$(grep Hugepagesize /proc/meminfo | awk '{print $2}')
SGA=$[128 * 1024 ** 2]
numberOfHugePages=$[$SGA/$hugepagesize]

# Shared Memory
mem=$(free -b | awk '/Mem/ {print $2}')
page=$(getconf PAGE_SIZE)
all=$(expr $mem \* 75 / 100 / $page + 1)
max=$(expr $all \* $page)

# GID
gid=$(getent group oinstall | awk -F ":" '{print $3}')

file="$sysctl_conf"
cat >> "$file" << EOF 

# Labs settings for oracle
# Memory settings
vm.swappiness = 10
vm.dirty_background_ratio = 3
vm.dirty_ratio = 40
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100

# HugePages
vm.nr_hugepages = $numberOfHugePages
vm.hugetlb_shm_group = $gid

# Shared Memory
kernel.shmmax = $max
kernel.shmall = $all
kernel.shmmni = 4096

# Semaphores
kernel.sem = 250 32000 100 128
EOF

# Limits setting
echo "Limits settings"
memlock=$[$numberOfHugePages*$hugepagesize]
file="$limits_conf"
cat >> "$file" << EOF 

# Labs settings for oracle
# Limits setting
oracle soft memlock $memlock 
oracle hard memlock $memlock 

# Open file descriptors for oracle user
oracle hard nofile 65536
EOF

function setGrub { 
    IFS== arr=($1) IFS=
    key=${arr[0]}
    value=${arr[1]}
    if [ $( grep -aEs $1 /proc/cmdline -q; echo $? ) -ne '0' ]; then
        file="/boot/grub/grub.conf"
        if [ $( grep -aEs $key $file -q; echo $? ) -eq '0' ]; then
            sed -i 's/\s'$key'=[^"\s\t]*\s/ /g' $file
            sed -i 's/\s'$key'=[^"\s\t]*$//g' $file
        fi
        sed -i '/^\s*kernel/ s/$/ '$1'/' $file 
    fi
}

function disableTuned {
    # Disabling transparent hugepages
    echo "Disabling transparent hugepages"
    service tuned stop
    chkconfig tuned off
    service ktune stop
    chkconfig ktune off
    # Append "transparent_hugepage=never" as a boot option.
    setGrub "transparent_hugepage=never"
}

# Add HugePage allocation as a boot option.
setGrub "hugepages=$numberOfHugePages" 


while true; do
    read -p "Do you want to disable tuned [Y/N]?" yn
    case $yn in
        [Yy] )
            disableTuned
            break
            ;;
        [Nn] )
            break
            ;;
        '' )
            disableTuned
            break
    esac
done


# I/O scheduler
echo "I/O scheduler settings"
# Add elevator=deadline as a boot option
setGrub "elevator=deadline" 

# reboot
while true; do
    read -p "Reboot the server for changes to take effect? [Y/N]" yn
    case $yn in
        [Yy] )
            reboot 
            break
            ;;
        [Nn] )
            break
            ;;
    esac
done
