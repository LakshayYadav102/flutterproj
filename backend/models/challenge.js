const mongoose = require("mongoose");

const ChallengeSchema = new mongoose.Schema({
  title: { type: String, required: true }, // Challenge name
  description: { type: String, required: true }, // Details about the challenge
  goal: { type: Number, required: true }, // Target CO2 reduction in kg
  duration: { type: Number, required: true }, // Duration in days
  startDate: { type: Date, default: Date.now }, // Start date
  endDate: { type: Date }, // End date (calculated automatically)
  participants: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }] // Users in the challenge
});

// Auto-calculate end date based on duration
ChallengeSchema.pre("save", function (next) {
  this.endDate = new Date(this.startDate);
  this.endDate.setDate(this.endDate.getDate() + this.duration);
  next();
});

module.exports = mongoose.model("Challenge", ChallengeSchema);
