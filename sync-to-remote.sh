#!/bin/sh
VERSION="4"

BACKUPS=(
    projects::$HOME/projects
    desktop::$HOME/Desktop
    documents::$HOME/Documents
    applications::$HOME/Applications)

REMOTE_NAME="gdrive-backup"
SYNC_EXCEPTIONS_FILENAME="sync-exceptions-default"
CUSTOM_SYNC_EXCEPTIONS_FILENAME="sync-exceptions"

DEVICE_NAME=$(scutil --get ComputerName)
USER_NAME=$USER
DATE=$(date +"%Y-%m-%d")
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Make capital letters lower-case
# Replace multiple consecutive dashes with a single dash
# Place a dash in front of the first capital letter of a group of capital letters
# Replace any space with a dash
simplify_text() {
    echo $1 \
    | tr ' ' '-' \
    | sed 's/\(.\)\([A-Z]\)/\1-\2/g' \
    | sed 's/-\{2,\}/-/g' \
    | tr '[:upper:]' '[:lower:]'
}

DEVICE_NAME_SIMPLE=$(simplify_text $DEVICE_NAME)
USER_NAME_SIMPLE=$USER_NAME

showHelp()
{
    echo "Backup v$VERSION"
    echo 
    echo "Usage:"
    echo "  $0 <command> [flags]"
    echo
    echo "Available Commands:"
    echo "  backup\tPerform backup"
    echo "  device\tShow device information"
    echo "  version\tShow version"
    echo "  help\tShow available commands and flags"
    echo
    echo "Available Flags:"
    echo "  -v --verbose\tVerbose output including all processed files"
    exit 1 # Exit script after printing help
}

perform_backup () {
    # Make sure the custom exceptions file exists
    touch $CUSTOM_SYNC_EXCEPTIONS_FILENAME

    printf "Backup device - name: %s, user: %s, date: %s\n" "$DEVICE_NAME" "$USER" "$DATE"
    for backup in "${BACKUPS[@]}" ;
    do
        BACKUP_NAME="${backup%%:*}"
        LOCAL_PATH="${backup##*:}"
        REMOTE_PATH="$USER_NAME_SIMPLE/$DEVICE_NAME_SIMPLE/$BACKUP_NAME"

        printf "Backup folder - time: %s, name: %s, source: %s, target: %s\n" "$(date +%T)" "$BACKUP_NAME" "$LOCAL_PATH" "$REMOTE_PATH"

        # Skip if source path does not exists
        if [ ! -d "$LOCAL_PATH" ]; 
        then
            printf "Source not found - skip.\n" "$BACKUP_NAME" "$LOCAL_PATH"
            continue
        fi
        
        # Plist requires absolute path to app
        # Dedupe first as 
        # 1. Google Drive supports multiple files with the same name co-existing
        # 2. Rclone sees duplicate files as errors during sync
        /usr/local/bin/rclone dedupe $REMOTE_NAME:$REMOTE_PATH/ --fast-list --dedupe-mode oldest $*
        /usr/local/bin/rclone sync "$LOCAL_PATH" $REMOTE_NAME:$REMOTE_PATH/ --backup-dir gdrive-backup:REMOTE_PATH-$DATE/ --create-empty-src-dirs --links --stats 10s --transfers 16 --drive-chunk-size 32M --checkers 32 --fast-list --exclude-from $SYNC_EXCEPTIONS_FILENAME --exclude-from $CUSTOM_SYNC_EXCEPTIONS_FILENAME $*

        # Exit if rclone returned an error
        #[ $? -ne 0 ] && exit $?

        printf "\n"
    done
}

#  The -t test option checks whether the stdin, [ -t 0 ],
#+ or stdout, [ -t 1 ], in a given script is running in a terminal.
if [ -t 0 ]
then # Interactive
    case $1 in
        backup)
            perform_backup --progress $2 $3 $4 $5 $6 $7 $8 $9
            ;;
        device)
            printf "About local:\n"
            printf "  Device name: %s\n" "$DEVICE_NAME"
            printf "  Simple device name: %s\n" "$DEVICE_NAME_SIMPLE"
            printf "  User name: %s\n" "$USER"
            printf "  Simple user name: %s\n" "$USER_NAME_SIMPLE"
            printf "  Date: %s\n" "$DATE"
            printf "  Script directory: %s\n" "$SCRIPT_DIR"
            echo
            printf "About remote:\n"
            printf "  Device name: %s\n" "$REMOTE_NAME"
            rclone about $REMOTE_NAME:
            ;;
        version)
            echo "Backup v$VERSION"
            ;;
        *)
            showHelp
    esac
else # Non-interactive
    echo "Switch to non-interactive mode"

    # Guard against running on battery power
    IS_AC_POWER = $(pmset -g ps | grep -c 'AC Power') # Power: 0 is battery; 1 is charger
    if [ $IS_AC_POWER -eq 0 ] ; then
        echo "Device on battery - exit.\n"
        exit 0
    fi
    
    perform_backup
fi
