# Put this in /etc/cron.hourly/backup
TARGET="gs://dokuwiki-cis91-forrest"

tar_file=/tmp/dokuwiki-backup-$(date +%s).tar.gz
tar -czf $tar_file /var/www/html 2>/dev/null 
gsutil cp $tar_file $TARGET
rm -f $tar_file