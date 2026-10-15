const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const rows = Array.from({ length: 60 }, (_, id) => ({ id: String(id), title: `Offer ${id}` }));
let pgOptions;
const fakePg = { BankOffer: { findAll: async options => {
  pgOptions = options;
  return rows.slice(options.offset, options.offset + options.limit);
} } };
require.cache[require.resolve('../models-pg')] = { exports: fakePg };
require.cache[require.resolve('../middleware/auth')] = { exports: {
  gentleAuthenticateJWT: (_req,_res,next)=>next(),
  authenticateJWT: (_req, _res, next) => next(), authorizeAdmin: (_req, _res, next) => next()
} };
require.cache[require.resolve('../models/BankOffer')] = { exports: { find: () => {
  let skip = 0, limit = 100;
  const query = {
    sort: () => query, skip: n => { skip = n; return query; },
    limit: n => { limit = n; return query; }, lean: async () => rows.slice(skip, skip + limit)
  };
  return query;
} } };
const router = require('../routes/bankOfferRoutes');

test('bank offer pages advance for Mongo and Postgres; invalid offsets are rejected', { timeout: 15000 }, async () => {
  const previous = process.env.DATA_SOURCE;
  const app = express();
  app.use('/api/bank-offers', router);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api/bank-offers`;
  try {
    for (const source of ['mongo', 'postgres']) {
      process.env.DATA_SOURCE = source;
      const first = await (await fetch(`${base}?limit=50`)).json();
      const second = await (await fetch(`${base}?limit=50&skip=50`)).json();
      assert.equal(first.length, 50);
      assert.equal(second.length, 10);
      assert.equal(second[0].id, '50');
      assert.equal(new Set([...first, ...second].map(row => row.id)).size, 60);
      assert.equal((await fetch(`${base}?skip=-1`)).status, 400);
      assert.equal((await fetch(`${base}?skip=100001`)).status, 400);
    }
    assert.equal(pgOptions.offset, 50);
    assert.deepEqual(pgOptions.order.at(-1), ['id', 'DESC']);
  } finally {
    if (previous === undefined) delete process.env.DATA_SOURCE;
    else process.env.DATA_SOURCE = previous;
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
});
