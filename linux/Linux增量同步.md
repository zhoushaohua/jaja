#!/bin/bash
export data=`date "+%Y-%m-%d_%H:%M:%S"`
rsync -vzurtopg --progress --delete /data/ root@192.168.100.150:/data >> $data.log