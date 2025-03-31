const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');  
const calculateRoutes = require('./routes/calculateRoutes');  
const activityRoutes = require('./routes/activityRoutes');
const challengeRoutes = require('./routes/challengeRoutes');
const profileRoutes = require("./routes/profileRoutes");
const blogRoutes = require("./routes/blogRoutes");
const leaderboardRoutes = require("./routes/leaderboard");

const app = express();

// Load environment variables
dotenv.config();
console.log("JWT_SECRET:", process.env.JWT_SECRET || "Secret key not found!");

// Enable CORS
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:3000",
  credentials: true,
}));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // ✅ Ensures form data is parsed properly


// Logging middleware for registration requests
app.use((req, res, next) => {
  if (req.path === "/api/auth/register" && req.method === "POST") {
    console.log("Incoming Registration Request:", req.body);
  }
  next();
});

// Profile Routes
app.use("/api/profile", profileRoutes);

// Serve static uploads
app.use("/uploads", express.static("uploads"));

// Blog Routes
app.use("/api/blogs", blogRoutes);

// Leaderboard Routes
if (leaderboardRoutes) {
  app.use("/api/leaderboard", leaderboardRoutes);
} else {
  console.error("❌ Error: leaderboardRoutes is not correctly imported.");
}

// Authentication Routes
if (authRoutes) {
  app.use('/api/auth', authRoutes);
} else {
  console.error("❌ Error: authRoutes is not correctly imported.");
}

// Carbon Footprint Routes
if (calculateRoutes) {
  app.use('/api', calculateRoutes);
} else {
  console.error("❌ Error: calculateRoutes is not correctly imported.");
}

// Activity Routes
if (activityRoutes) {
  app.use('/api/activities', activityRoutes);
} else {
  console.error("❌ Error: activityRoutes is not correctly imported.");
}

// Register Challenge Routes
if (challengeRoutes) {
  app.use('/api/challenges', challengeRoutes);
} else {
  console.error("❌ Error: challengeRoutes is not correctly imported.");
}

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
  .then(() => {
    console.log("✅ MongoDB connected successfully");
  })
  .catch((error) => {
    console.error("❌ MongoDB connection error:", error);
    process.exit(1);
  });

// Start server
const port = process.env.PORT || 5000;
app.listen(port, () => {
  console.log(`🚀 Server is running on port ${port}`);
});
