
# ZFS-Backup

The zfs backing-up tool. ha-ha.

## Tools

- `zb-snap <zfs_object>` creates a snapshot
- `zb-cleanup <zfs_object> <density> [max age]` destroys unnecessary
  snapshots
- `zb-pull <ssh_connection> <local_zfs_object> <remote_zfs_object>` pulls most
  recent snapshots of `remote_zfs_object` to `local_zfs_object`, using ssh
  called with `ssh_connection`

## Requirements

`bash` shell and `zfs` utils are needed. `zb-pull` requires `ssh`.

zfs-backup requires GNU `date` or compatible, other `date` programs may fail.
Test is simple, check if this command works for you:

	date --date=now

## Installation

Run `make install`, it installs itself to some `sbin/`. You can also specify
`DESTDIR=/usr/local/` or similar.

For local changes (command aliases/wrappers, `PATH` setting etc.), file
`$HOME/.zb-rc` is sourced before any commands are run.

## Example

	$ zb-snap tank/test
	$ zfs list -t snapshot
	NAME                                    USED  AVAIL  REFER  MOUNTPOINT
	tank/test@zb-2014-06-07_10:46:19_p0200     0      -    34K  -

	$ zb-snap tank/test
	$ zb-snap tank/test
	$ zb-snap tank/test
	$ zfs list -t snapshot
	NAME                                    USED  AVAIL  REFER  MOUNTPOINT
	tank/test@zb-2014-06-07_10:46:19_p0200     0      -    34K  -
	tank/test@zb-2014-06-07_10:46:51_p0200     0      -    34K  -
	tank/test@zb-2014-06-07_10:46:52_p0200     0      -    34K  -
	tank/test@zb-2014-06-07_10:46:54_p0200     0      -    34K  -

	$ zb-cleanup tank/test 200
	$ zfs list -t snapshot
	NAME                                    USED  AVAIL  REFER  MOUNTPOINT
	tank/test@zb-2014-06-07_10:46:19_p0200     0      -    34K  -
	tank/test@zb-2014-06-07_10:46:54_p0200     0      -    34K  -

	---- other machine ----

	$ zb-pull root@first.machine.example.com tank/test tank/repl
	$ zfs list -t snapshot
	NAME                                    USED  AVAIL  REFER  MOUNTPOINT
	tank/repl@zb-2014-06-07_10:46:19_p0200     0      -    34K  -
	tank/repl@zb-2014-06-07_10:46:54_p0200     0      -    34K  -


## Recommended usage and a word about density

There is a long-time backup weirdness about that everyone wants some "hourly
backups" along with "daily backups", "monthly backups", sometimes "weekly",
"yearly", "full-moon", "christmas" and "ramadan".

I don't like this approach simply for it's not machine-enough. Instead, I
choose to generate the backups regularly, and forget some of the backups from
time to time. Obvious way to achieve a good ratio between how many backups to
hold vs. their age is "less with the time", e.g. "for backups that are X hours
old, don't keep backups that are closer than X/10 hours apart".

This creates a pretty good logarithmic distribution of datapoints in time, can
be generally extended to any backup scheme, and looks cool because there is no
god damned human timing.

From there, my setup goes like this:

- run `zb-snap` every night (or every hour, if I want it to be denser; it
  generally doesn't really matter).
- run `zb-cleanup` with density around 400 to cleanup old stuff

And on remote backup machines:

- `zb-pull` every morning
- `zb-cleanup` with a slightly higher density number (it keeps more backups)

## FAQ
#### What exactly does zb-cleanup clean up?

Candidates for backup deletion are determined like this:

1. if shapshot is older than `max_age`, delete it right away.
2. get two historically subsequent snapshots. Determine time in seconds since
   the newer was created is X seconds, time since the older was created is Y.
   Obviously X is less than Y.
3. Calculate `density*(Y-X)/Y`. If the result is less than 1.0, delete the
   _closer_ backup.

#### How to determine your density and other numbers?

Density is "maximum ratio of time between backups to age of backups, in
percent".

Good approach to determine it (with all the other numbers) is this:

1. Take several time specifications of how much backups you want:
  - "I want at least 7 backups per last week"
  - "I need One backup daily"
  - "I want at least 4 backups per month"
  - "I want one backup yearly"
2. Convert them to reasonable numbers to the sortof table:
  - 7 times, 7 days
  - 1 time, 1 day
  - 4 times, 31 days
  - 1 time, 365 days
3. Get your `density` as maximal value from the first column, and `max_age` as
   maximum of the second column. Run zb-cleanup periodically with that values.
   E.g. in our example: `zb-cleanup data/set 700 '1 year ago'`.
4. Setup cron to run zb-snap periodically in time interval same as minimum
   value from the second row - in our case, daily. (probably in morning or
   somehow off-peak hours).

#### It doesn't work from cron!

Check if the environment is the same as when you test the stuff from the command line. At least two common caveats exist:

- `PATH` may be different in cron (which may select wrong `date` program to
  run, or not find something other like custom-installed `zfs`). Edit
  `~/.zb-rc` and fix `PATH` there.
- Some SSH authentication methods may not work from cron environment due to
  missing `ssh-agent`, especially the password-protected privkeys. Descriptions
  of many workarounds are available around the internet.

## Disclaimer

Be sure to verify that this software really fits your use-case before you use
it. Backups are precious.
