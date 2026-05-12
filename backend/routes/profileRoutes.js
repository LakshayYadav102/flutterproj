const express = require("express");
const multer = require("multer");
const { CloudinaryStorage } = require("multer-storage-cloudinary"); // 🟢 Added
const cloudinary = require("../config/cloudinary"); // 🟢 Added (Make sure this path points to your cloudinary.js file!)
const jwt = require("jsonwebtoken");
const User = require("../models/user");

// Import all models to calculate the wallet breakdown
const Activity = require("../models/activity");
const Donation = require("../models/Donation");
const Ride = require("../models/Ride");
const Booking = require("../models/Booking");
const FoodDonation = require("../models/FoodDonation");
const EcoVideo = require("../models/EcoVideo");

const router = express.Router();

// 🟢 NEW: Cloudinary Storage Setup for Profile Pictures
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: "greenverse_profiles",
    allowed_formats: ["jpg", "png", "jpeg", "webp"],
  },
});

const upload = multer({ storage });

const verifyToken = (req) => {
  const token = req.header("Authorization");
  if (!token) throw new Error("No token, authorization denied");
  const decoded = jwt.verify(token.split(" ")[1], process.env.JWT_SECRET);
  return decoded.userId; 
};

// Fetch User Profile
router.get("/", async (req, res) => {
  try {
    const userId = verifyToken(req); 
    const user = await User.findById(userId).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
});

// Fetch Just the Wallet Balance for Navbar
router.get("/wallet", async (req, res) => {
  try {
    const userId = verifyToken(req);
    const user = await User.findById(userId).select("greenCoins");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json({ greenCoins: user.greenCoins || 0 });
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
});

// Fetch Detailed Wallet Breakdown & SYNC PAST DATA
router.get("/wallet-details", async (req, res) => {
  try {
    const userId = verifyToken(req);
    const user = await User.findById(userId).select("greenCoins");
    if (!user) return res.status(404).json({ message: "User not found" });

    // 1. GreenTrail
    const activitiesCount = await Activity.countDocuments({ userId });
    const activityCoins = activitiesCount * 1;

    const donations = await Donation.find({ user: userId });
    const treesPlanted = donations.reduce((sum, d) => sum + (d.treesSponsored || 0), 0);
    const treeCoins = treesPlanted * 4;
    const greenTrailTotal = activityCoins + treeCoins;

    // 2. Carpooling
    const ridesOffered = await Ride.countDocuments({ driver: userId });
    const rideOfferCoins = ridesOffered * 2;

    const bookings = await Booking.countDocuments({ passenger: userId, status: "confirmed" });
    const bookingCoins = bookings * 2;
    const carpoolTotal = rideOfferCoins + bookingCoins;

    // 3. Food Waste
    const foodDonations = await FoodDonation.find({ donor: userId, status: "ACCEPTED" });
    let foodCarbonSaved = 0;
    let foodCoins = 0;
    foodDonations.forEach(d => {
      foodCarbonSaved += (d.carbonSaved || 0);
      foodCoins += Math.max(1, Math.round((d.carbonSaved || 0) / 5));
    });

    // 4. EcoLearn
    const videos = await EcoVideo.find({ user: userId });
    let videoViews = 0;
    let videoCoins = 0;
    videos.forEach(v => {
      videoViews += (v.views || 0);
      videoCoins += Math.floor((v.views || 0) / 50);
    });

    const calculatedTotal = greenTrailTotal + carpoolTotal + foodCoins + videoCoins;

    let finalCoins = user.greenCoins || 0;
    if (calculatedTotal > finalCoins) {
      await User.findByIdAndUpdate(userId, { greenCoins: calculatedTotal });
      finalCoins = calculatedTotal;
      console.log(`Retroactively synced wallet for user ${userId} to ${calculatedTotal} coins.`);
    }

    res.json({
      totalCoins: finalCoins, 
      breakdown: {
        greenTrail: { activitiesCount, activityCoins, treesPlanted, treeCoins, total: greenTrailTotal },
        carpool: { ridesOffered, rideOfferCoins, bookings, bookingCoins, total: carpoolTotal },
        foodWaste: { donationsCount: foodDonations.length, foodCarbonSaved: Number(foodCarbonSaved.toFixed(2)), total: foodCoins },
        ecoLearn: { videosCount: videos.length, videoViews, total: videoCoins }
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update User Profile
router.put("/", async (req, res) => {
  try {
    const userId = verifyToken(req); 
    const { username, mobile, dob, address } = req.body;
    
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    user.username = username || user.username;
    user.mobile = mobile || user.mobile;
    user.dob = dob || user.dob;
    user.address = address || user.address;

    await user.save();
    res.json({ message: "Profile updated successfully", user });
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
});

// Upload Profile Picture
router.post("/upload", upload.single("profilePic"), async (req, res) => {
  try {
    const userId = verifyToken(req); 
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // 🟢 NEW: Cloudinary returns the full absolute URL in req.file.path
    if (!req.file || !req.file.path) {
      return res.status(400).json({ message: "No image uploaded" });
    }

    user.profilePic = req.file.path; // Save Cloudinary URL to DB
    await user.save();
    
    res.json({ message: "Profile picture updated", profilePic: user.profilePic });
  } catch (error) {
    console.error("Profile Pic Upload Error:", error);
    res.status(500).json({ message: "Failed to upload image" });
  }
});

module.exports = router;