#!/bin/bash

# Variables
MONGODUMP="/usr/bin/mongodump"
MONGO_HOSTS="nsi-mongo-01.ns2online.com.br:27017,nsi-mongo-02.ns2online.com.br:27017,nsi-mongo-03.ns2online.com.br:27017"
MONGO_USER="backup_user"
MONGO_PASS=$(echo $(cat /etc/db_auth.cfg) | base64 --decode)
BKP_DIR="/bkp"
BKP_TMP="$BKP_DIR/$(hostname -a)"
BKP_NAME="$(hostname -a)-$(date +%F-%H%M)"
LOG_DIR="/var/log/mongoBackup"
PID_FILE="/var/run/mongoBackup.pid"
NUM_DUMPS="10"
NUM_LOGS="60"

# Functions
log() {
    echo "$(date +%F) $(date +%H%M) | $@" >> $LOG_DIR/$(hostname -a).$(date +%F).log
}

log_begin() {
    log "------------------------------- Backup Begin -------------------------------"
}

log_end() {
    log "-------------------------------- Backup End --------------------------------"
}

create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p $1
        log "$1 directory was created"
    fi
}

pidfile_check() {
    if [ -e $PID_FILE ]; then
        log "MongoBackup already running. Leaving."
        log_end
        exit
    fi
}

pidfile_create() {
    pidfile_check
    echo $$ > $PID_FILE
    log "Pidfile was created."
}

pidfile_remove() {
    rm -rf $PID_FILE
    log "Pidfile was removed."
}

is_master() {
    IS_MASTER=$(mongo --quiet --eval "d=db.isMaster(); print( d['ismaster'] );")
    if [ "$IS_MASTER" == "true" ]; then
        log "This MongoDB node is master. Leaving."
        pidfile_remove
        log_end
        exit
    else
        log "This MongoDB node is slave. Proceeding..."
    fi
}

dump_cleanup() {
    rm -rf $BKP_TMP
    log "Uncompressed dump was cleaned"
}

is_running() {
    if [ $(pgrep $1 | wc -l) -ne 0 ]; then
        dump_cleanup
        log "$1 is running. Leaving."
        pidfile_remove
        log_end
        exit
    fi
}

dump_replicaset() {
    is_running mongodump
    log "Starting mongodump..."
    $MONGODUMP --quiet -h $MONGO_HOSTS -u $MONGO_USER -p $MONGO_PASS --out $BKP_TMP
    if [ $? -eq 0 ]; then
        log "Mongodump completed successfully"
    else
        dump_cleanup
        log "Mongodump failed"
        pidfile_remove
        log_end
        exit
    fi
}

dump_compress() {
    is_running tar
    tar czf $BKP_DIR/$BKP_NAME.tar.gz $BKP_TMP
    log "Dump compression completed successfully"
}

dump_cleanup_old() {
    if [ $(ls -d1rt $BKP_DIR/*.tar.gz | head -n -$NUM_DUMPS | wc -l) -gt 0 ]; then
        log "Old dumps files:"
        for i in $(ls -d1rt $BKP_DIR/*.tar.gz | head -n -$NUM_DUMPS); do
            log "$i"
        done
        ls -d1rt $BKP_DIR/*.tar.gz | head -n -$NUM_DUMPS | xargs rm
        log "Old dumps was cleaned successfully"
    else
        log "No old dumps found"
    fi
}

log_cleanup_old() {
    if [ $(ls -d1rt $LOG_DIR/*.log | head -n -$NUM_LOGS | wc -l) -gt 0 ]; then
        log "Old log files:"
        for i in $(ls -d1rt $LOG_DIR/*.log | head -n -$NUM_LOGS); do
            log "$i"
        done
        ls -d1rt $LOG_DIR/*.log | head -n -$NUM_LOGS | xargs rm
        log "Old logs was cleaned successfully"
    else
        log "No old logs found"
    fi
}

# Main
create_dir $LOG_DIR     # Create log directory
log_begin               # Begin log transaction
pidfile_create          # Creating Pidfile
is_master               # Checking if MongoDB is master
create_dir $BKP_TMP     # Create backup directory
dump_cleanup            # Cleanup uncompressed dump (if exists)
dump_replicaset         # Begin mongodump for all dbs from replicaset
dump_compress           # Compressing dumped databases
dump_cleanup            # Cleanup uncompressed dump
dump_cleanup_old        # Cleanup old compressed dump (1 Day Old)
log_cleanup_old         # Cleanup old logs
pidfile_remove          # Removing Pidfile
log_end                 # End log transaction