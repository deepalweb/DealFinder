#!/bin/bash

# DealFinder startup script for Azure App Service (Linux)
# This script starts both backend and frontend on the same App Service

echo "🚀 Starting DealFinder application..."

# Start backend in background
echo "🔧 Starting backend server on port 8080..."
cd /home/site/wwwroot/backend
npm install --production > /dev/null 2>&1
node server.js &
BACKEND_PID=$!

# Wait for backend to start
sleep 5

# Start frontend
echo "🎨 Starting frontend server on port 3000..."
cd /home/site/wwwroot/frontend-next
npm install --production > /dev/null 2>&1
npm start &
FRONTEND_PID=$!

echo "✅ Both services started"
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"

# Keep the script running
wait
