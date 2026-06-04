#!/bin/bash

# DealFinder startup script for Azure App Service (Linux)
# This script starts the backend which automatically spawns Next.js

echo "🚀 Starting DealFinder application..."

# Start backend - it will spawn Next.js internally
echo "🔧 Starting backend server on port 8080..."
cd /home/site/wwwroot/backend
npm install --production > /dev/null 2>&1
node server.js
