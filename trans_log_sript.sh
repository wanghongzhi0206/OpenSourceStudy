#!/bin/bash
VPN_LOG_PATH="/var/log/openvpn/"
VPN_LOG_FILE="*.log"
MOUNT_POINT="/home/whz/work/smb/mntshare/"
LAST_TRANS_DATE_FILE="/home/whz/work/smb/last.timestamp"
TRANS_LOG="/home/whz/work/smb/copyLog.log"

if [ ! -e $LAST_TRANS_DATE_FILE ]; then
  echo "19900101 00:00" > $LAST_TRANS_DATE_FILE
fi

# get last copy file date and current time
last_date=`cat $LAST_TRANS_DATE_FILE`
current_time=`date '+%Y%m%d %H:%M'`

# copy log file to mount point
files=`find $VPN_LOG_PATH -newermt "$last_date" -name "$VPN_LOG_FILE"`
if [ $? -ne 0 ]; then
  echo "$current_time [ERROR] copy log file failed"
  exit 1
fi

SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
files=($files) # split to array $files
IFS=$SAVEIFS   # Restore IFS

# copy log file to samba server
for file in ${files[@]}
do
  echo "$file"
  cp -fup $file $MOUNT_POINT
  if [ $? -ne 0 ]; then
    echo "$current_time [ERROR] copy log file failed" >> $TRANS_LOG
    exit 1
  fi
done

# append copy success log to log file, and update transport log date
echo "$current_time [INFO] copy log file successful" >> $TRANS_LOG
echo  $current_time > $LAST_TRANS_DATE_FILE
exit 0
