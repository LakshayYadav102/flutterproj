const express = require("express");
const multer = require("multer");
const path = require("path");
const jwt = require("jsonwebtoken");
const User = require("../models/user");

const router = express.Router();

// 📂 Storage Configuration for Profile Pictures
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/"); // Save files to "uploads/" directory
  },
  filename: (req, file, cb) => {
    cb(null, `${req.userId}_${Date.now()}${path.extname(file.originalname)}`);
  },
});

const upload = multer({ storage });

// ✅ Function to verify JWT inside each route
const verifyToken = (req) => {
  const token = req.header("Authorization");
  if (!token) throw new Error("No token, authorization denied");

  const decoded = jwt.verify(token.split(" ")[1], process.env.JWT_SECRET);
  return decoded.userId; // ✅ Extract user ID from token
};

// 🟢 1️⃣ Fetch User Profile
router.get("/", async (req, res) => {
  try {
    const userId = verifyToken(req); // ✅ Verify JWT
    const user = await User.findById(userId).select("-password");

    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
});

// 🔵 2️⃣ Update User Profile
router.put("/", async (req, res) => {
  try {
    const userId = verifyToken(req); // ✅ Verify JWT
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

// 🟠 3️⃣ Upload Profile Picture
router.post("/upload", upload.single("profilePic"), async (req, res) => {
  try {
    const userId = verifyToken(req); // ✅ Verify JWT
    const user = await User.findById(userId);
    
    if (!user) return res.status(404).json({ message: "User not found" });

    user.profilePic = `/uploads/${req.file.filename}`;
    await user.save();

    res.json({ message: "Profile picture updated", profilePic: user.profilePic });
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
});

module.exports = router;
