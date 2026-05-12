const mongoose = require("mongoose");

const vehicleSchema = new mongoose.Schema({
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  vehicleType: {
    type: String,
    enum: ['Car', 'Bike', 'EV Scooter', 'EV Car'],
    required: true,
  },
  model: {
    type: String,
    required: true,
  },
  registrationNumber: {
    type: String,
    required: true,
    unique: true,
  },
  seatsAvailable: {
    type: Number,
    required: true,
    min: 1,
  },
  isElectric: {
    type: Boolean,
    default: false,
  },
  batteryRange: {
    type: Number,
    default: 0, // only for EV
    min: 0
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Add index for owner
vehicleSchema.index({ owner: 1 });

module.exports = mongoose.model('Vehicle', vehicleSchema);