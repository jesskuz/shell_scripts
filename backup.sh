#!/bin/bash
# This is simply sample code with absolutely no guarantee(s) of functionality.  Use at your own risk.


# Specify the backup output directory
directory=/var/backup

# Select the day to rebuild the database
full_backup_day=Monday

# Switch to the folder
cd "$directory"

# Backup mysql and app data
rsync -zaq --delete /var/lib/mysql .
rsync -zaq --delete /var/lib/app . 

# Delete backup files to force rebuild of tar index
if [ `date +%A` == "$full_backup_day" ];
then

     find /data/backup -maxdepth 1 -regextype posix-egrep -regex ".*full\.snapshot$" -delete
     find /data/backup -maxdepth 1 -regextype posix-egrep -regex "/var/backup/[0-9]{10}-[a-z]+\.tar\.xz" -delete

     # find /data/backup/ -ctime 7 -iname "*.full.snapshot" -delete;

fi

# Perform differential backup
# Tar nested directories using xzip compression and a timestamped incremental backup file
for file in *; do
     if [[ -d $file ]]; 
     then
          tar --listed-incremental=$file.full.snapshot -cJf "$(date +%s)-$file.tar.xz" $file;
     fi  

done
