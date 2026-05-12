// models/Ride.js
const mongoose = require("mongoose");

const rideSchema = new mongoose.Schema({
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },
  vehicle: {
    make: { type: String, required: true },
    model: { type: String, required: true },
    licensePlate: { type: String, required: true },
    carType: { 
      type: String, 
      enum: ["Sedan", "SUV", "Hatchback", "Van", "Electric", "Other"], 
      required: true 
    },
    totalSeats: { type: Number, required: true, min: 1 },
    fuelType: { 
      type: String, 
      enum: ["Petrol", "Diesel", "Electric", "Hybrid"], 
      required: true 
    }
  },
  from: { type: String, required: true },
  to: { type: String, required: true },
  date: { type: Date, required: true },
  time: { type: String, required: true },
  seatsAvailable: { type: Number, required: true, min: 0 },
  pricePerSeat: { type: Number, required: true, min: 0 },
  distance: { type: Number, min: 0 }, // Estimated distance in km
  estimatedDuration: { type: String }, // e.g., "2 hours 30 minutes"
  stops: [{ type: String }], // Optional intermediate stops
  luggageSpace: { 
    type: String, 
    enum: ["Small", "Medium", "Large", "None"], 
    default: "None" 
  },
  smokingAllowed: { type: Boolean, default: false },
  petsAllowed: { type: Boolean, default: false },
  additionalNotes: { type: String, trim: true },
  carbonOffset: { type: Boolean, default: false },
  passengers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  }],
  messages: [{
    sender: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    message: { type: String, required: true },
    timestamp: { type: Date, default: Date.now }
  }],
  status: { type: String, enum: ["upcoming", "ongoing", "completed", "cancelled"], default: "upcoming" },
  matchedRequest: { type: mongoose.Schema.Types.ObjectId, ref: "RideRequest" },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model("Ride", rideSchema);