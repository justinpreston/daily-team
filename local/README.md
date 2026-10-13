# Local routine

Runs the daily team on your own machine each morning instead of in GitHub Actions or a cloud session. Nothing is published or committed except the upstream sync.

Each run:

1. Syncs this fork with `isas1/daily-team` (merge, then push to `origin main`). On a conflict it aborts the merge and carries on.
2. Runs `claude -p` in build mode, allowed only `sh team.sh`, Read, Write, Edit, Glob and Grep.
3. Writes `team-builds/<date>/session.md` and `artifact-1.html` (ignored through `.git/info/exclude`).
4. Shows a notification with the decision and opens the artifact.

Logs go to `~/Library/Logs/daily-team/<date>.log`.

## Set up on macOS

```sh
git clone https://github.com/justinpreston/daily-team ~/code/daily-team
cd ~/code/daily-team && claude   # accept the trust prompt once, then exit
cp local/com.justinpreston.daily-team.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.justinpreston.daily-team.plist
launchctl kickstart -k gui/$(id -u)/com.justinpreston.daily-team   # test now
```

It runs daily at 05:50 local time, or on wake if the Mac was asleep. To clone somewhere else, set `DAILY_TEAM_REPO` and change the path in the plist.

On Linux, use cron instead: `50 5 * * * $HOME/code/daily-team/local/daily-team-local.sh`.
