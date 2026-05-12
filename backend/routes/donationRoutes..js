const express = require('express');
const router = express.Router();
const Donation = require('../models/Donation');
const Activity = require('../models/activity'); 
const User = require('../models/user'); // 🟢 Required to update GreenCoins

// Calculate lifetime carbon footprint
router.get('/lifetime-carbon/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const activities = await Activity.find({ userId });

    const totalEmissions = activities.reduce((sum, act) => sum + act.totalEmission, 0);
    res.json({ lifetimeCarbon: totalEmissions }); // in kg
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Calculate how many trees needed to offset
router.get('/trees-needed/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const activities = await Activity.find({ userId });

    const totalEmissions = activities.reduce((sum, act) => sum + act.totalEmission, 0);
    const treesNeeded = Math.ceil(totalEmissions / 21.77); // 1 tree ≈ 21.77kg CO₂/year

    res.json({ treesNeeded });
  } catch (err) {
    res.status(500).json({ error: 'Error calculating trees needed' });
  }
});

// Submit a donation with transaction ID
router.post('/submit-transaction', async (req, res) => {
  try {
    const { userId, amount, transactionId } = req.body;

    if (!userId || !amount || !transactionId || amount < 100) {
      return res.status(400).json({ error: 'Invalid input: userId, amount (minimum 100), and transactionId are required' });
    }

    const treesSponsored = Math.floor(amount / 100); // ₹100 = 1 tree
    const donation = new Donation({
      user: userId,
      amount,
      treesSponsored,
      transactionId
    });

    await donation.save();

    // 🟢 Gamification: Reward GreenCoins for offsetting CO2
    // Rule: 1 coin per 5kg CO2. 1 Tree = ~21.77kg CO2. 
    // 21.77 / 5 = ~4.35. We award 4 GreenCoins per tree sponsored!
    const coinsEarned = Math.max(1, treesSponsored * 4);

    try {
      await User.findByIdAndUpdate(userId, { $inc: { greenCoins: coinsEarned } });
      console.log(`🎉 Awarded ${coinsEarned} GreenCoins to user ${userId} for planting ${treesSponsored} trees!`);
    } catch (rewardError) {
      console.error("Failed to award coins for donation:", rewardError);
    }

    res.status(201).json({ 
      message: 'Transaction submitted successfully', 
      donation,
      coinsEarned 
    });
  } catch (err) {
    console.error('Transaction submission failed:', err);
    res.status(500).json({ error: 'Transaction submission failed' });
  }
});

// Get donation history
router.get('/history/:userId', async (req, res) => {
  try {
    const donations = await Donation.find({ user: req.params.userId }).sort({ date: -1 });
    res.json({ donations }); 
  } catch (err) {
    console.error('Error fetching donation history:', err);
    res.status(500).json({ error: 'Failed to fetch donation history' });
  }
});

module.exports = router;