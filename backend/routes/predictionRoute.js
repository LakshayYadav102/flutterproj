const express = require('express');
const axios = require('axios');
const router = express.Router();

// POST /api/predict
router.post('/predict', async (req, res) => {
    try {
      const { transportation, energy, dietType, predictionRange } = req.body;
  
      // Predict directly for selected range
      const totalTransport = transportation * (predictionRange / 7);
      const totalEnergy = energy * (predictionRange / 7);
  
      const response = await axios.post('http://127.0.0.1:5000/predict', {
        Transportation: totalTransport,
        Energy: totalEnergy,
        DietType: dietType,
      });
  
      const totalPrediction = response.data.predicted_total_emission;
  
      res.json({ predicted_total_emission: totalPrediction });
    } catch (error) {
      console.error('Error contacting Flask API:', error.message);
      res.status(500).json({ error: 'Prediction failed' });
    }
  });
  
module.exports = router;
