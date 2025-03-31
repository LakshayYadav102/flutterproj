const mongoose = require('mongoose');

// Define the Activity Schema
const activitySchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "User", 
    required: true 
  }, // Link to User model
  fromDate: { 
    type: Date, 
    required: true 
  }, // Start date of the activity
  toDate: { 
    type: Date, 
    required: true 
  }, // End date of the activity
  transportation: { 
    type: Number, 
    required: true, 
    min: 0 
  }, // Distance in km (Non-negative)
  diet: { 
    type: String, 
    required: true 
  }, // Vegetarian/Non-Vegetarian
  energy: { 
    type: Number, 
    required: true, 
    min: 0 
  }, // Energy usage in kWh (Non-negative)
  totalEmission: { 
    type: Number, 
    required: true 
  }, // Total carbon emissions
  timestamp: { 
    type: Date, 
    default: Date.now 
  }, // Activity timestamp (defaults to current date if not provided)
});

// Create and export the Activity model
module.exports = mongoose.model('Activity', activitySchema);