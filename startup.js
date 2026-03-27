// startup.js - Azure production entry point
// Runs Next.js standalone on port 3000 and Express API on port 8080
// Azure iisnode routes all traffic to this file via web.config

const { spawn } = require('child_process');
const path = require('path');
const http = require('http');
const httpProxy = require('http-proxy-middleware');
const express = require('express');

// Start Next.js standalone server
const nextServerPath = path.join(__dirname, 'frontend-next/.next/standalone/frontend-next/server.js');
const nextProcess = spawn('node', [nextServerPath], {
  env: { ...process.env, PORT: '3000', HOSTNAME: '127.0.0.1' },
  stdio: ['ignore', 'pipe', 'pipe']
});

nextProcess.stdout.on('data', d => console.log('[Next.js]', d.toString().trim()));
nextProcess.stderr.on('data', d => console.error('[Next.js]', d.toString().trim()));
nextProcess.on('exit', code => console.log('[Next.js] exited with code', code));

// Wait for Next.js to be ready then start the proxy
setTimeout(() => {
  const app = express();
  const PORT = process.env.PORT || 8080;

  // Load backend API routes
  require('./backend/server.js');

  console.log('Startup complete');
}, 5000);
