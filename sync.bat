@echo off
echo Syncing from GitHub...
git fetch origin
git reset --hard origin/main
echo Sync complete!
pause