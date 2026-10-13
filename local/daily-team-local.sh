#!/bin/sh
# Local daily-team routine: sync fork with upstream, then have Claude Code build today's team + artifact.
# Output: $REPO/team-builds/<date>/ (git-ignored locally). Log: ~/Library/Logs/daily-team/<date>.log
set -u
REPO="${DAILY_TEAM_REPO:-$HOME/code/daily-team}"
DAY=$(date +%F)
LOGDIR="$HOME/Library/Logs/daily-team"
mkdir -p "$LOGDIR"
exec >>"$LOGDIR/$DAY.log" 2>&1
echo "=== $(date) ==="
cd "$REPO" || { echo "no repo at $REPO"; exit 1; }

notify() { osascript -e "display notification \"$2\" with title \"Daily team\" subtitle \"$1\"" >/dev/null 2>&1 || true; }

# 1. Sync fork with upstream (deterministic, in shell, not by the model)
sync="up to date"
git checkout -q main && git pull -q --ff-only origin main || sync="pull failed"
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/isas1/daily-team
if git fetch -q upstream main; then
  before=$(git rev-parse HEAD)
  if git merge -q --no-edit upstream/main; then
    if [ "$(git rev-parse HEAD)" != "$before" ]; then
      git push -q origin main && sync="merged upstream" || sync="merged, push failed"
    fi
  else
    git merge --abort; sync="merge conflict, skipped"
  fi
else
  sync="fetch failed"
fi
echo "sync: $sync"

# Keep build output out of git status
grep -qx 'team-builds/' .git/info/exclude 2>/dev/null || echo 'team-builds/' >> .git/info/exclude

# 2. Build today's session + artifact
claude -p "Use SKILL.md in this repo in build mode, count 1, no brief. Run sh team.sh for today's team. Read prompt.md sections Work the brief, Referee (only after a Deadlock, once), Build an artifact, and Writing rules. Write the session to team-builds/$DAY/session.md and the artifact to team-builds/$DAY/artifact-1.html. Run the SKILL.md Review checklist and fix until every item passes. Do not run any other script, and do not commit or push. End by printing one line: DECISION: <the decision in under 20 words>." \
  --permission-mode acceptEdits \
  --allowedTools "Bash(sh team.sh)" "Read" "Write" "Edit" "Glob" "Grep" \
  > "$LOGDIR/$DAY.out"
status=$?
cat "$LOGDIR/$DAY.out"

out="$REPO/team-builds/$DAY/artifact-1.html"
decision=$(grep -m1 '^DECISION:' "$LOGDIR/$DAY.out" | cut -c11- | tr -d '"')
if [ -f "$out" ]; then
  notify "$DAY · sync: $sync" "${decision:-Artifact ready}"
  open "$out" 2>/dev/null || xdg-open "$out" >/dev/null 2>&1 || true
else
  notify "$DAY · failed" "No artifact (exit $status). See $LOGDIR/$DAY.log"
fi

exit "$status"
