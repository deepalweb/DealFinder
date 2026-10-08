// Postgres-backed BankOffer CRUD, matching the Mongo-backed route's shape.
// Gated behind DATA_SOURCE=postgres.
const { Op } = require('sequelize');
const { v4: uuidv4 } = require('uuid');
const pg = require('../models-pg');

// Sequelize DECIMAL columns come back as strings from the pg driver (unlike Mongoose,
// which always returned real numbers) — mobile/web clients do strict numeric casts.
function toNumberOrNull(value) {
  if (value === null || value === undefined) return null;
  const n = Number(value);
  return Number.isNaN(n) ? null : n;
}

function serialize(offer) {
  const o = offer.toJSON ? offer.toJSON() : offer;
  return {
    ...o,
    _id: o.id,
    minimumSpend: toNumberOrNull(o.minimumSpend),
    maximumBenefit: toNumberOrNull(o.maximumBenefit),
  };
}

async function listActive({ limit = 100 } = {}) {
  const now = new Date();
  const offers = await pg.BankOffer.findAll({
    where: {
      status: { [Op.in]: ['active', 'scheduled'] },
      startDate: { [Op.lt]: new Date(now.getTime() + 24 * 60 * 60 * 1000) },
      endDate: { [Op.gte]: now },
    },
    order: [['featured', 'DESC'], ['priority', 'DESC'], ['createdAt', 'DESC']],
    limit,
  });
  return offers.map(serialize);
}

async function listAll() {
  const offers = await pg.BankOffer.findAll({ order: [['createdAt', 'DESC']] });
  return offers.map(serialize);
}

async function getById(id) {
  const offer = await pg.BankOffer.findByPk(id);
  return offer ? serialize(offer) : null;
}

async function create(payload) {
  const offer = await pg.BankOffer.create({ id: uuidv4(), ...payload });
  return serialize(offer);
}

async function update(id, payload) {
  const offer = await pg.BankOffer.findByPk(id);
  if (!offer) return null;
  await offer.update(payload);
  return serialize(offer);
}

async function remove(id) {
  const offer = await pg.BankOffer.findByPk(id);
  if (!offer) return false;
  await offer.destroy();
  return true;
}

module.exports = { listActive, listAll, getById, create, update, remove };
