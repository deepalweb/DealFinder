// temporary_hash_generator.js
// This script is used to generate a bcrypt hash for a given password.
// Useful for manually updating a password in the database if it was stored in plain text.

const bcrypt = require('bcryptjs');
const readline = require('readline').createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log("--- Password Hash Generator ---");
console.log("This script will generate a bcrypt hash for the password you enter.");
console.log("Use this hash to manually update a user's password field in the database if it was incorrectly stored as plain text.");
console.log("---------------------------------");

readline.question('Enter the password to hash (e.g., admin123): ', (passwordToHash) => {
  if (!passwordToHash) {
    console.error("Error: No password entered. Exiting.");
    readline.close();
    process.exit(1);
  }

  try {
    const saltRounds = 10; // Standard number of salt rounds
    const salt = bcrypt.genSaltSync(saltRounds);
    const hashedPassword = bcrypt.hashSync(passwordToHash, salt);

    console.log("\n--- Generated Hash ---");
    console.log(`Original Password: ${passwordToHash}`);
    console.log(`Salt Rounds: ${saltRounds}`);
    console.log(`Hashed Password: ${hashedPassword}`);
    console.log("----------------------");
    console.log("\nACTION: Copy the 'Hashed Password' value and update the user's password field in your MongoDB database.");
    console.log("Example MongoDB command: db.users.updateOne({ email: \"user@example.com\" }, { $set: { password: \"PASTE_HASH_HERE\" } });");

  } catch (error) {
    console.error("\nError generating hash:", error.message);
  } finally {
    readline.close();
  }
});
