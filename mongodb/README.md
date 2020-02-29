MongoDB Scripts
===

Scripts to automate MongoDB.

# mongo-backup.sh
You must to create a schedule on the operate system to running this script properly

Install
```
git clone https://github.com/daniloharuo/mongo-backup.git /tmp/mongo-backup
cp -r /tmp/mongo-backup/mongo-backup.sh /usr/local/bin/mongo-backup
chmod +x /usr/local/bin/mongo-backup
```

Crontab Example:
```
$cat /etc/cron.d/mongo-backup
# mongo-backup schedule: Run every 3 hours and 3 minutes
03 */3 * * * mongod /usr/local/bin/mongo-backup
```
