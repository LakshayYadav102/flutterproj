require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');

// Route Imports
const authRoutes = require('./routes/authRoutes');
const calculateRoutes = require('./routes/calculateRoutes');
const activityRoutes = require('./routes/activityRoutes');
const challengeRoutes = require('./routes/challengeRoutes');
const profileRoutes = require('./routes/profileRoutes');
const blogRoutes = require('./routes/blogRoutes');
const predictionRoute = require('./routes/predictionRoute');
const donationRoutes = require('./routes/donationRoutes.');
const leaderboardRoutes = require("./routes/leaderboard"); // Re-added for mobile games
const rideRoutes = require('./routes/rideRoutes');
const evRoutes = require('./routes/evRoutes');
const foodDonationRoutes = require("./routes/foodDonationRoutes");
const foodConversationRoutes = require("./routes/foodConversationRoutes");
const ecolearnRoutes = require("./routes/ecolearnRoutes");
const storeRoutes = require("./routes/storeRoutes");
const corporateRoutes = require('./routes/corporateRoutes');

// Model Imports for Sockets and Cron Jobs
const Ride = require("./models/Ride");
const User = require("./models/user");
const Booking = require("./models/Booking");
const FoodDonation = require("./models/FoodDonation");
const FoodConversation = require("./models/FoodConversation");

const app = express();

// Increased limit for mobile image/file uploads
app.use(express.json({ limit: '150mb' }));
app.use(express.urlencoded({ extended: true, limit: '150mb' }));

const server = http.createServer(app);

// Socket.io configuration - Origin set to * for seamless mobile debugging
const io = socketIo(server, {
  cors: {
    origin: "*", 
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
  }
});

console.log("[ENV LOAD CHECK] MONGO_URI:", process.env.MONGO_URI ? "present" : "MISSING");
console.log("[ENV LOAD CHECK] JWT_SECRET:", process.env.JWT_SECRET ? "present" : "MISSING");
console.log("[ENV LOAD CHECK] CLOUDINARY_URL:", process.env.CLOUDINARY_URL || "MISSING");

// Enable CORS for API requests
app.use(cors({
  origin: "*", // Allows mobile device requests without Origin header blocks
  credentials: true,
}));

// Request Logging Middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  res.on('finish', () => {
    console.log(`[${new Date().toISOString()}] Response sent: ${req.method} ${req.url} - Status ${res.statusCode}`);
  });
  next();
});

// Serve static uploads
app.use('/uploads', express.static('uploads'));

// API Routes mounting
app.use('/api/ev', evRoutes);
app.use('/api/auth', authRoutes);
app.use('/api', calculateRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/challenges', challengeRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/blogs', blogRoutes);
app.use('/api', predictionRoute);
app.use('/api/donations', donationRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/riderequests', rideRoutes);
app.use("/api/food-donations", foodDonationRoutes);
app.use("/api/food-conversations", foodConversationRoutes);
app.use("/api/ecolearn", ecolearnRoutes);
app.use("/api/store", storeRoutes);
app.use('/api/corporate', corporateRoutes);

// Health Check
app.get('/api/test', (req, res) => {
  res.json({ message: 'Server is running correctly for Greenverse Mobile' });
});

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('Server error:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method
  });
  res.status(500).json({ message: 'Internal server error', error: err.message });
});

// --- CRON JOB: Expire Food Donations ---
const expireFoodDonations = async () => {
  try {
    const now = new Date();
    const expiredDonations = await FoodDonation.find({
      status: "AVAILABLE",
      expiryTime: { $lt: now },
    });

    for (const donation of expiredDonations) {
      donation.status = "EXPIRED";
      if (donation.foodCategory === "raw") {
        donation.expiredHandling = "COMPOST";
      } else {
        donation.expiredHandling = "ANIMAL_FEED";
      }
      await donation.save();
    }

    if (expiredDonations.length > 0) {
      console.log(`[Food Expiry Job] ${expiredDonations.length} donation(s) expired`);
    }
  } catch (error) {
    console.error("[Food Expiry Job Error]", error);
  }
};

setInterval(() => {
  expireFoodDonations();
}, 10 * 60 * 1000);

// --- SOCKET.IO REALTIME LOGIC ---
io.on('connection', (socket) => {
  console.log('User connected via Mobile App:', socket.id);

  // -- RIDES SHARING SOCKETS --
  socket.on('joinRide', (rideId) => {
    socket.join(rideId);
    console.log(`User ${socket.id} joined ride ${rideId}`);
  });

  socket.on('sendMessage', async ({ rideId, message, senderId }) => {
    try {
      const ride = await Ride.findById(rideId);
      if (!ride) return console.error(`Ride ${rideId} not found`);

      const isDriver = ride.driver.toString() === senderId;
      const isPassenger = ride.passengers.some(p => p.toString() === senderId);
      const hasBooking = await Booking.exists({ ride: rideId, passenger: senderId });
      
      if (!isDriver && !isPassenger && !hasBooking) {
        return console.error(`User ${senderId} is not authorized to send messages for ride ${rideId}`);
      }

      const newMsg = { sender: senderId, message, timestamp: new Date() };
      ride.messages.push(newMsg);
      await ride.save();

      const sender = await User.findById(senderId, "username");
      io.to(rideId).emit('newMessage', {
        sender: { _id: senderId, name: sender.username },
        message,
        timestamp: new Date()
      });
    } catch (err) {
      console.error(`Error processing message for ride ${rideId}:`, err.message);
    }
  });

  // -- FOOD DONATION SOCKETS --
  socket.on("joinFoodConversation", (conversationId) => {
    const room = `food_${conversationId}`;
    socket.join(room);
    console.log(`User ${socket.id} joined food conversation ${conversationId}`);
  });

  socket.on("sendFoodMessage", async ({ conversationId, senderId, message }) => {
    try {
      const conversation = await FoodConversation.findById(conversationId);
      if (!conversation) return console.error(`Conversation ${conversationId} not found`);

      if (conversation.donor.toString() !== senderId && conversation.receiver.toString() !== senderId) {
        return console.error(`User ${senderId} not authorized for conversation ${conversationId}`);
      }

      const newMessage = { sender: senderId, message, timestamp: new Date() };
      conversation.messages.push(newMessage);
      await conversation.save();

      const populatedConversation = await FoodConversation.findById(conversationId).populate("messages.sender", "username");

      io.to(`food_${conversationId}`).emit("newFoodMessage", {
        conversation: populatedConversation,
      });
    } catch (err) {
      console.error("Food Socket Error:", err.message);
    }
  });

  socket.on('disconnect', () => {
    console.log('Mobile User disconnected:', socket.id);
  });
});

// --- MONGODB CONNECTION & SERVER START ---
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ MongoDB connected successfully'))
  .catch((error) => {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  });

const port = process.env.PORT || 5001; // Kept at 5001 to match your Flutter API Service
server.listen(port, () => {
  console.log(`🚀 Greenverse Backend is running on port ${port}`);
});