console.log("🚀 Starting Corporate Seed Script...");

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/user'); 
require('dotenv').config();

const dbUri = process.env.MONGO_URI || process.env.DATABASE_URL;

if (!dbUri) {
    console.error("❌ ERROR: No MongoDB URI found. Check your .env file!");
    process.exit(1);
}

const seedTechCorpData = async () => {
  try {
    console.log("🔌 Attempting to connect to database...");
    await mongoose.connect(dbUri);
    console.log('🌱 Connected to Database successfully!');

    const companyDomain = 'techcorp';
    const db = mongoose.connection.db;

    console.log(`🧹 Clearing old ${companyDomain} users...`);
    await User.deleteMany({ companyName: companyDomain });

    console.log("👥 Generating 50 fake employees...");
    const fakeEmployees = [];
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('password123', salt);
    const departments = ['Engineering', 'Sales', 'HR & Admin', 'Marketing'];

    for (let i = 1; i <= 50; i++) {
      fakeEmployees.push(new User({
        username: `TechCorp_Employee_${i}`,
        email: `employee${i}@techcorp.com`,
        password: hashedPassword,
        role: 'user',
        companyName: companyDomain,
        totalCarbonFootprint: Math.floor(Math.random() * 400) + 100,
        greenCoins: Math.floor(Math.random() * 1000),
        address: departments[Math.floor(Math.random() * departments.length)]
      }));
    }

    const savedUsers = await User.insertMany(fakeEmployees);
    console.log(`✅ Injected 50 employees!`);

    console.log("📊 Generating module data (Rides, Food, Videos)...");
    const fakeRides = [];
    const fakeFood = [];
    const fakeVideos = [];

    savedUsers.forEach(user => {
      if (Math.random() > 0.5) fakeRides.push({ driver: user._id, seats: 3, status: 'completed', date: new Date() });
      if (Math.random() > 0.6) fakeFood.push({ donor: user._id, quantity: Math.floor(Math.random() * 10) + 2, status: 'claimed' });
      if (Math.random() > 0.8) fakeVideos.push({ uploader: user._id, title: "Eco Tip", views: Math.floor(Math.random() * 100) });
    });

    if (fakeRides.length > 0) await db.collection('rides').insertMany(fakeRides);
    if (fakeFood.length > 0) await db.collection('fooddonations').insertMany(fakeFood);
    if (fakeVideos.length > 0) await db.collection('ecovideos').insertMany(fakeVideos);

    console.log(`🎉 SUCCESS! Injected ${fakeRides.length} Rides, ${fakeFood.length} Food Donations, and ${fakeVideos.length} Videos!`);
    
    process.exit(0);
  } catch (err) {
    console.error('❌ FATAL ERROR during seeding:', err);
    process.exit(1);
  }
};

seedTechCorpData();