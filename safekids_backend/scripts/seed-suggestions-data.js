require('dotenv').config();
const mongoose = require('mongoose');
const Location = require('../src/models/Location');

const CHILD_ID = '68f42a52a99ce5fd1089a5db'; // Replace with actual child ID

const seedData = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
    if (!mongoUri) {
      console.error('❌ MONGODB_URI not found in .env');
      process.exit(1);
    }
    await mongoose.connect(mongoUri);
    console.log('✅ MongoDB Connected');

    // Clear existing test data
    await Location.deleteMany({ userId: CHILD_ID });
    console.log('🗑️ Cleared old data');

    // Locations for cluster 1: Trường THCS (3 days, 3 locations per day)
    const schoolCluster = [
      // 2025-10-19
      { lat: 10.8484, lng: 106.7730, day: 19 },
      { lat: 10.8485, lng: 106.7731, day: 19 },
      { lat: 10.8483, lng: 106.7729, day: 19 },
      
      // 2025-10-18
      { lat: 10.8484, lng: 106.7730, day: 18 },
      { lat: 10.8485, lng: 106.7731, day: 18 },
      { lat: 10.8483, lng: 106.7729, day: 18 },
      
      // 2025-10-17
      { lat: 10.8484, lng: 106.7730, day: 17 },
      { lat: 10.8485, lng: 106.7731, day: 17 },
      { lat: 10.8483, lng: 106.7729, day: 17 },
    ];

    // Locations for cluster 2: Công viên (3 days, 3 locations per day)
    const parkCluster = [
      // 2025-10-19
      { lat: 10.8280, lng: 106.7490, day: 19 },
      { lat: 10.8281, lng: 106.7491, day: 19 },
      { lat: 10.8279, lng: 106.7489, day: 19 },
      
      // 2025-10-18
      { lat: 10.8280, lng: 106.7490, day: 18 },
      { lat: 10.8281, lng: 106.7491, day: 18 },
      { lat: 10.8279, lng: 106.7489, day: 18 },
      
      // 2025-10-17
      { lat: 10.8280, lng: 106.7490, day: 17 },
      { lat: 10.8281, lng: 106.7491, day: 17 },
      { lat: 10.8279, lng: 106.7489, day: 17 },
    ];

    const locations = [...schoolCluster, ...parkCluster].map(loc => {
      const date = new Date(2025, 9, loc.day, 10 + Math.random() * 8, Math.random() * 60);
      return {
        userId: CHILD_ID,
        latitude: loc.lat,
        longitude: loc.lng,
        accuracy: 10,
        batteryLevel: 80,
        timestamp: date
      };
    });

    await Location.insertMany(locations);
    console.log(`✅ Added ${locations.length} test locations for child: ${CHILD_ID}`);

    const count = await Location.countDocuments({ userId: CHILD_ID });
    console.log(`📊 Total locations: ${count}`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

seedData();
