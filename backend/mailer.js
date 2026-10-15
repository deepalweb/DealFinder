const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.office365.com',
  port: 587,
  secure: false,
  requireTLS:true,
  connectionTimeout:10000,
  greetingTimeout:10000,
  socketTimeout:15000,
  auth: {
    user: process.env.M365_EMAIL,
    pass: process.env.M365_PASSWORD || process.env.EMAIL_PASSWORD
  }
});

module.exports = transporter;
