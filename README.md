# Sync to Remote

This shell script syncs local folders to a remote storage.

## Requirements

- Tested on MacOS Big Sur. Might work on other releases.

## Todo

- [ ] Make script self-updating on run
- [ ] Move todo to GitHub project boards

## Installation

Install the package manager [Homebrew](https://brew.sh/).

### Install Rclone

```sh
brew install rclone
```

### Configure Rclone

- [rclone.org](https://rclone.org)
- [rclone.org/drive/](https://rclone.org/drive/) - Google Drive

```sh
rclone config
```

Choose the following options for Google Drive:

- menu option -> new remote
- name -> gdrive
- type -> drive (Google Drive)
- client_id -> <Google Cloud Project - Google Drive API auth>
- client_secret -> <Google Cloud Project - Google Drive API auth>
- scope -> 1
- root_folder_id -> <empty>
- service_account_file -> <empty>
- Edit advanced config -> no
- Use auto config -> no
- Configure this as a team drive -> no for 'my drive', yes for a shared drive

## Usage

### Run from the command line

```sh
./sync-to-remote.sh <command> [flags]
```

Use the command `help` to see an overview of available commands and flags.

### Schedule as a launchd agent

> When the computer is running on battery power, no scheduled sync takes place, unless forced by providing the `backup` command.

Make the project files accessible to all users of a machine by placing it in `/Users/Shared`. For a single user; a more limited location such as ~/Applications can be used.

By making a shallow clone of the git repository (using `--depth 1`), only the most recent changes are downloaded.

```sh
git clone --depth 1 https://github.com/averstuyf/av-tool-sync-to-remote.git /Users/Shared/av-tool-sync-to-remote/
```

In the future update the clone, overwriting any local changes.

```sh
cd /Users/Shared/av-tool-sync-to-remote
git fetch
git reset --hard origin/master
git clean -f
```

Make a symlink to the [launchd agent config](https://manpagez.com/man/5/launchd.plist/) file in `/Library/LaunchAgents` for all users or `~/Library/LaunchAgents` for a specific user.

```sh
sudo ln -s /Users/Shared/av-tool-sync-to-remote/com.av.sync-to-remote.plist /Library/LaunchAgents/com.av.sync-to-remote.plist
```

Have launchd load the agent.

```sh
launchctl load /Library/LaunchAgents/com.av.sync-to-remote.plist
```

See script output and errors.

```sh
cat /tmp/sync-to-remote.stdout
cat /tmp/sync-to-remote.stderr
```

## License

This repository is [licensed](LICENSE.md) under the permissive MIT License.

---

Copyright (c) 2020 [Arnaud Verstuyf](https://github.com/averstuyf).
