const mongoose = require("mongoose");

const UserChallengeSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }, // Reference to User
  challengeId: { type: mongoose.Schema.Types.ObjectId, ref: "Challenge", required: true }, // Reference to Challenge
  progress: { type: Number, default: 0 }, // CO2 reduction progress in kg
  completed: { type: Boolean, default: false }, // Whether the challenge is completed
  joinedAt: { type: Date, default: Date.now } // Timestamp when the user joined
});

module.exports = mongoose.model("UserChallenge", UserChallengeSchema);
