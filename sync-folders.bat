@echo off
echo Setting up sparse checkout for backend and frontend only...

git config core.sparseCheckout true
echo backend/ > .git\info\sparse-checkout
echo frontend/ >> .git\info\sparse-checkout

git pull origin main

echo Sync complete - only backend and frontend folders updated!
pause