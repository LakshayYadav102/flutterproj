const express = require('express');
const router = express.Router();
const Activity = require('../models/activity'); 
const User = require('../models/user'); // 🟢 Required to update GreenCoins
const mongoose = require('mongoose'); 

// POST route to save activity data
router.post('/save', async (req, res) => {
  const { fromDate, toDate, transportData, houseData, lifestyleData, carbonFootprint, userId } = req.body;

  try {
    // Validate required fields but allow 0 values
    if (
      !fromDate || !toDate || !userId || 
      transportData.distance === undefined || 
      houseData.electricityUsage === undefined || 
      houseData.lpgUsage === undefined || 
      lifestyleData.diet === undefined || 
      carbonFootprint === undefined
    ) {
      console.error("Missing required fields:", { fromDate, toDate, transportData, houseData, lifestyleData, carbonFootprint, userId });
      return res.status(400).json({ message: "All fields are required, but 0 values are allowed" });
    }

    // Convert userId to ObjectId before saving
    const validUserId = new mongoose.Types.ObjectId(userId);

    // Create a new activity instance
    const newActivity = new Activity({
      userId: validUserId,
      fromDate,
      toDate,
      transportation: transportData.distance || 0,
      diet: lifestyleData.diet || "vegetarian", 
      energy: houseData.electricityUsage || 0, 
      totalEmission: carbonFootprint || 0, 
    });

    console.log("Saving activity to database:", newActivity);
    await newActivity.save();

    // 🟢 Gamification: Reward 1 GreenCoin for tracking carbon footprint
    try {
      await User.findByIdAndUpdate(validUserId, { $inc: { greenCoins: 1 } });
      console.log(`🎉 Awarded 1 GreenCoin to user ${userId} for tracking carbon footprint!`);
    } catch (rewardError) {
      console.error("Failed to award coin for logging activity:", rewardError);
    }

    res.status(201).json({ message: 'Activity saved successfully! You earned 1 GreenCoin.' });
  } catch (err) {
    console.error('Error saving activity:', err);
    res.status(500).json({ message: 'Error saving activity', error: err.message });
  }
});

// Get activities by userId
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log('Received userId:', userId);

    if (!/^[0-9a-fA-F]{24}$/.test(userId)) {
      return res.status(400).json({ message: 'Invalid User ID format' });
    }

    const activities = await Activity.find({ userId });

    if (activities.length === 0) {
      return res.status(404).json({ message: 'No activities found' });
    }

    res.json(activities);
  } catch (err) {
    console.error('Error fetching activities:', err);
    res.status(500).json({ message: 'Error fetching activities' });
  }
});

// Route to fetch carbon footprint data for graphing
router.get('/footprint/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const activities = await Activity.find({ userId }).sort({ fromDate: 1 });

    if (!activities.length) {
      return res.status(404).json({ message: 'No activities found for this user' });
    }

    const labels = activities.map(activity => new Date(activity.fromDate).toLocaleDateString());
    const values = activities.map(activity => activity.totalEmission);

    res.json({ labels, values });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error retrieving data for graph' });
  }
});

module.exports = router;