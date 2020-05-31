#!/bin/bash

# Paramater
#  $1: samba server share folder
#  $2: samba user
#  $3: samba user password
#  $4: on off flag
#  $5 crontab minute hour
#  $6 crontab hour

SSH_KEY_PATH="/home/whz/.ssh/"
#SSH_KEY_PATH="/home/vpnmanager/.ssh/"
SSH_KEY_NAME="thinclsvpn.key"
SSH_KEY="$SSH_KEY_PATH$SSH_KEY_NAME"
VPN_USER="whz"
VPN_LOG_FILE="/var/log/openvpn/*.log"
TRANS_LOG_SCRIPT="/home/whz/work/smb/trans_log_sript.sh"
MOUNT_POINT="/home/whz/work/smb/mntshare/"

#if [ `whoami` != "root" ]; then
#  echo "Execute this script as root user." >&2
#  exit 1
#fi

function connect_smbserver () {
  # connect smaba server
  smbclient -L $SMB_SERVER -U=$USER%$PASSWORD > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo $ret
    echo "[ERROR]connect smaba server failed!"
    exit 128
  fi
}

function mount_smbserver () {
  # if $MOUNT_POINT is mounted, umount mount point  
  if mountpoint -q $MOUNT_POINT; then
    umount $MOUNT_POINT
  fi

  # mount smaba server  
  mount.cifs $SMB_SERVER $MOUNT_POINT -o rw,username=$USER,password=$PASSWORD
  if [ $? -ne 0 ]; then
    echo "[ERROR]mount smaba server failed!"
    exit 129
  fi
  
  fstab=`cat /etc/fstab|grep -v $MOUNT_POINT`
  smb_fstab="$SMB_SERVER $MOUNT_POINT cifs user=$USER,password=$PASSWORD,defaults 0 0"
  echo -e "$fstab\n$smb_fstab" 
  echo -e "$fstab\n$smb_fstab" > /etc/fstab
  if [ $? -ne 0 ]; then
    echo "[ERROR]automount smaba server to /etc/fstab failed!"
    exit 130
  fi
}

function umount_smbserver () {
  # if $MOUNT_POINT is mounted, umount mount point
  if mountpoint -q $MOUNT_POINT; then
    umount $MOUNT_POINT
    fstab=`cat /etc/fstab|grep -v $MOUNT_POINT`
    echo "$fstab" > /etc/fstab
  fi
}

function setup_crontab () {
  # if sript file not exist,  exit
  if [ ! -e $TRANS_LOG_SCRIPT ]; then
         echo "$TRANS_LOG_SCRIPT  not exist!"
         exit 1
  fi
  
  cronDescription="$minute $hour * * * $TRANS_LOG_SCRIPT > /dev/null 2>&1"

  # get current cron not include transport log cron
  cron=`crontab -l|grep -v $TRANS_LOG_SCRIPT`

  # setup crontab
  echo -e "$cron\n$cronDescription" | crontab
  return $?
}

function delete_crontab () {
  # if sript file not exist,  exit
  if [ ! -e $TRANS_LOG_SCRIPT ]; then
         echo "$TRANS_LOG_SCRIPT  not exist!"
         exit 1
  fi

  # get current cron not include transport log cron
  cron=`crontab -l|grep -v $TRANS_LOG_SCRIPT`

  # setup crontab
  echo "$cron" | crontab
  return $?
}


# main function
SMB_SERVER=$1
USER=$2
PASSWORD=$3
ON_OFF=$4

if [ $ON_OFF -eq 1 ]; then
  # connect smaba server
  connect_smbserver

  # mount smaba server
  mount_smbserver
  
  hour=$5
  minute=$6
  # setup crontab
  setup_crontab
else
  # umount smaba server
  umount_smbserver

  # delete crontab
  delete_crontab
fi
exit $?
