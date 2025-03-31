const express = require('express');
const router = express.Router();
const Activity = require('../models/activity');
const User = require('../models/user'); // Assuming there's a User model
const mongoose = require('mongoose');

// GET leaderboard - Last 7 days lowest carbon footprint
router.get('/', async (req, res) => {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // Aggregate total emissions per user in the last 7 days
    const leaderboard = await Activity.aggregate([
      {
        $match: {
          fromDate: { $gte: sevenDaysAgo } // Filter last 7 days
        }
      },
      {
        $group: {
          _id: "$userId",
          totalEmission: { $sum: "$totalEmission" }
        }
      },
      {
        $sort: { totalEmission: 1 } // Ascending order (Lowest emissions first)
      },
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "user"
        }
      },
      {
        $unwind: "$user"
      },
      {
        $project: {
          _id: 0,
          userId: "$user._id",
          username: "$user.username",
          totalEmission: 1
        }
      }
    ]);

    res.json(leaderboard);
  } catch (err) {
    console.error("Error fetching leaderboard:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
