const express = require('express');
const Activity = require('../models/activity'); // Import the Activity model
const User = require('../models/user'); // Import the User model
const router = express.Router();

// POST route to save activity data
router.post('/save', async (req, res) => {
  const { fromDate, toDate, transportData, houseData, lifestyleData, userId } = req.body;

  // Calculate carbon footprint
  const transportCarbon = transportData.distance * (transportData.fuelType === 'gasoline' ? 0.25 : 0.2); // Example values
  const houseCarbon = houseData.energyUsage * 0.1; // Example value
  const lifestyleCarbon = lifestyleData.diet === 'non-vegetarian' ? 1.2 : 1.0; // Example value

  const carbonFootprint = transportCarbon + houseCarbon + lifestyleCarbon;

  try {
    // Create a new activity entry
    const activity = new Activity({
      userId, // Associate with the logged-in user
      fromDate,
      toDate,
      transportData,
      houseData,
      lifestyleData,
      carbonFootprint
    });

    // Save the activity to the database
    await activity.save();

    res.status(201).json({ message: 'Data saved successfully', activity });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error saving data' });
  }
});

// GET route to retrieve all activity data for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const activities = await Activity.find({ userId: req.params.userId });

    res.status(200).json({ activities });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error retrieving activities' });
  }
});
// GET route to predict emission from the latest activity
router.get('/predict-latest/:userId', async (req, res) => {
  const axios = require('axios'); // Import axios here
  try {
    const latestActivity = await Activity.findOne({ userId: req.params.userId }).sort({ fromDate: -1 });

    if (!latestActivity) {
      return res.status(404).json({ error: 'No activity found for this user' });
    }

    const transport = latestActivity.transportData?.distance || 0;
    const energy = latestActivity.houseData?.energyUsage || 0;
    const dietType = latestActivity.lifestyleData?.diet === 'vegetarian' ? 0 : 1;

    const payload = {
      transportation: transport,
      energy: energy,
      dietType: dietType,
    };

    const response = await axios.post('http://localhost:5000/predict', payload);

    res.status(200).json({ prediction: response.data.predicted_total_emission });

  } catch (err) {
    console.error('Prediction error:', err);
    res.status(500).json({ error: 'Prediction failed' });
  }
});


module.exports = router;
