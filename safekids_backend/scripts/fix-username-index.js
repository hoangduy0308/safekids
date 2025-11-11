/**
 * Fix script: Drop old username index and let Mongoose recreate it properly
 * Run: node scripts/fix-username-index.js
 */

require('dotenv').config();
const mongoose = require('mongoose');

async function fixUsernameIndex() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('users');

    // Get all indexes
    const indexesCursor = collection.listIndexes();
    const indexes = await indexesCursor.toArray();
    console.log('\n📊 Current indexes on users collection:');
    indexes.forEach(idx => console.log(`  - ${idx.name}: ${JSON.stringify(idx.key)}`));

    // Drop the problematic index if it exists
    const indexNames = indexes.map(idx => idx.name);
    
    if (indexNames.includes('username_1')) {
      console.log('\n🗑️  Dropping old username_1 index...');
      await collection.dropIndex('username_1');
      console.log('✅ Dropped username_1 index');
    }

    if (indexNames.includes('username_1_unique')) {
      console.log('\n🗑️  Dropping old username_1_unique index...');
      await collection.dropIndex('username_1_unique');
      console.log('✅ Dropped username_1_unique index');
    }

    // Remove all null usernames from existing records
    console.log('\n🔄 Cleaning up null usernames...');
    const result = await collection.deleteMany({ username: null });
    console.log(`✅ Deleted ${result.deletedCount} documents with null username`);

    // Close connection
    await mongoose.connection.close();
    console.log('\n✅ Fix completed! Restart your server to recreate proper indexes.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

fixUsernameIndex();
