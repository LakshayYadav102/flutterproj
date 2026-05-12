// routes/leaderboard.js
const express = require("express");
const Activity = require("../models/activity"); 
const User = require("../models/user");

const router = express.Router();

// 🔹 GET /api/leaderboard (Global 7-Day Leaderboard)
router.get("/", async (req, res) => {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const leaderboardData = await Activity.aggregate([
      // 1. Filter activities strictly to the last 7 days
      {
        $match: {
          fromDate: { $gte: sevenDaysAgo }
        }
      },
      // 2. Group by user and sum up their total emissions
      {
        $group: {
          _id: "$userId",
          totalEmission: { $sum: "$totalEmission" }
        }
      },
      // 3. Join with the Users collection to get usernames and profile pics
      {
        $lookup: {
          from: "users", // Note: Ensure this matches your actual MongoDB collection name for users (usually lowercase plural)
          localField: "_id",
          foreignField: "_id",
          as: "userDetails"
        }
      },
      // 4. Flatten the user details array
      { $unwind: "$userDetails" },
      // 5. Format the final output to match what Flutter expects
      {
        $project: {
          _id: 0,
          userId: "$_id",
          username: "$userDetails.username",
          profilePic: "$userDetails.profilePic",
          // Round to 2 decimal places for a cleaner UI
          totalEmission: { $round: ["$totalEmission", 2] } 
        }
      },
      // 6. Sort by lowest emissions first (The actual "Winner")
      {
        $sort: { totalEmission: 1 } 
      }
    ]);

    res.json(leaderboardData);
  } catch (err) {
    console.error("Error fetching global leaderboard:", err);
    res.status(500).json({ message: "Server error while fetching leaderboard" });
  }
});

module.exports = router;