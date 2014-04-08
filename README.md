
# ZFS-Backup

The zfs backing-up tool. ha-ha.

## Tools:

- `zb-snap <volume>` creates a snapshot
- `zb-cleanup <volume> <density>` destroys unnecessary snapshots
- `zb-pull <volume> <remote_volume> <ssh_options>` pulls most recent snapshot of `remote_volume` to `volume`, using ssh called with `ssh_options`
- `zb-cron` reads configuration from `/etc/zfs-backup.conf` and executes above 3 commands with config-specified parameters
