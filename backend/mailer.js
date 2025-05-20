const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.office365.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.M365_EMAIL,
    pass: process.env.M365_PASSWORD
  }
});

module.exports = transporter;