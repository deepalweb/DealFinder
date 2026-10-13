// USB development bridge: avoids unrelated IPv4 localhost services on port 8080.
// Run alongside the backend, then: adb reverse tcp:8080 tcp:18080
const net = require('net');
const server = net.createServer((phone) => {
  const backend = net.connect({ host: '::1', port: 8080 });
  phone.pipe(backend);
  backend.pipe(phone);
  phone.on('error', () => backend.destroy());
  backend.on('error', () => phone.destroy());
  phone.on('close', () => backend.destroy());
  backend.on('close', () => phone.destroy());
});
server.on('error', (error) => {
  console.error(`Mobile API bridge failed: ${error.code}`);
  process.exitCode = 1;
});
server.listen(18080, '127.0.0.1', () => {
  console.log('Mobile API bridge: 127.0.0.1:18080 -> [::1]:8080');
});
