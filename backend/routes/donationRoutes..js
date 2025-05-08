const express = require('express');
const router = express.Router();
const Donation = require('../models/Donation');
const Activity = require('../models/activity'); // Assuming you store emissions here

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
    res.status(201).json({ message: 'Transaction submitted successfully', donation });
  } catch (err) {
    console.error('Transaction submission failed:', err);
    res.status(500).json({ error: 'Transaction submission failed' });
  }
});

// Get donation history
router.get('/history/:userId', async (req, res) => {
  try {
    const donations = await Donation.find({ user: req.params.userId }).sort({ date: -1 });
    res.json({ donations }); // Wrap in object to match frontend expectation
  } catch (err) {
    console.error('Error fetching donation history:', err);
    res.status(500).json({ error: 'Failed to fetch donation history' });
  }
});

module.exports = router;