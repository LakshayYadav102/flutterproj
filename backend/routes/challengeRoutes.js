const express = require("express");
const Challenge = require("../models/challenge");
const UserChallenge = require("../models/userChallenge");
const Activity = require("../models/activity"); // ✅ Import Activity model to calculate footprint
const User = require("../models/user");
const mongoose = require("mongoose");  // ✅ Add this line at the top

const router = express.Router();

// 🔹 Get all active challenges
router.get("/", async (req, res) => {
  try {
    const challenges = await Challenge.find();
    res.json(challenges);
  } catch (err) {
    console.error("Error fetching challenges:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// 🔹 Add a new challenge (Admin-only or for testing)
router.post("/add", async (req, res) => {
  const { title, description, goal, duration } = req.body;

  if (!title || !description || !goal==undefined || !duration) {
    return res.status(400).json({ message: "All fields are required" });
  }

  try {
    const newChallenge = new Challenge({ title, description, goal, duration });
    await newChallenge.save();
    res.status(201).json({ message: "Challenge added successfully!", challenge: newChallenge });
  } catch (err) {
    console.error("Error adding challenge:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// 🔹 Join a challenge
router.post("/join", async (req, res) => {
  const { userId, challengeId } = req.body;

  try {
    // Check if user already joined
    const existingEntry = await UserChallenge.findOne({ userId, challengeId });
    if (existingEntry) {
      return res.status(400).json({ message: "You have already joined this challenge." });
    }

    // Add user to challenge
    const newEntry = new UserChallenge({ userId, challengeId });
    await newEntry.save();

    // Add user to challenge's participant list
    await Challenge.findByIdAndUpdate(challengeId, { $push: { participants: userId } });

    res.status(201).json({ message: "Challenge joined successfully!" });
  } catch (err) {
    console.error("Error joining challenge:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// 🔹 Update progress in a challenge
router.post("/update-progress", async (req, res) => {
  const { userId, challengeId, progress } = req.body;

  try {
    const userChallenge = await UserChallenge.findOne({ userId, challengeId });

    if (!userChallenge) {
      return res.status(404).json({ message: "You are not part of this challenge." });
    }

    // Update progress
    userChallenge.progress += progress;

    // Check if the challenge is completed
    const challenge = await Challenge.findById(challengeId);
    if (userChallenge.progress >= challenge.goal) {
      userChallenge.completed = true;
    }

    await userChallenge.save();
    res.json({ message: "Progress updated successfully!", userChallenge });
  } catch (err) {
    console.error("Error updating progress:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// 🔹 Get leaderboard (Ranked by Least CO₂ in the Last 7 Days)
router.get("/leaderboard", async (req, res) => {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // Get CO₂ footprint for all users in the last 7 days
    const userFootprints = await Activity.aggregate([
      { $match: { fromDate: { $gte: sevenDaysAgo } } }, // Filter recent activities
      {
        $group: {
          _id: "$userId",
          totalCO2: { $sum: "$totalEmission" } // ✅ Ensure correct field name
        }
      },
      { $sort: { totalCO2: 1 } } // Sort by least CO₂ footprint
    ]);

    // Fetch usernames from the User model
    const leaderboard = await Promise.all(
      userFootprints.map(async (entry) => {
        const user = await User.findById(entry._id).select("username");
        return {
          userId: entry._id,
          username: user ? user.username : "Unknown User",
          totalCO2: entry.totalCO2
        };
      })
    );

    res.json(leaderboard);
  } catch (err) {
    console.error("Error fetching leaderboard:", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router; // ✅ Ensure the router is exported!
