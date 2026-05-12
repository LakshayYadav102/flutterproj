const mongoose = require("mongoose");

const ratingSchema = new mongoose.Schema({
  ride: { type: mongoose.Schema.Types.ObjectId, ref: "Ride", required: true },
  reviewer: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  reviewee: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  rating: { type: Number, min: 1, max: 5, required: true },
  review: { type: String },
}, { timestamps: true });

ratingSchema.index({ ride: 1, reviewer: 1 });

module.exports = mongoose.model("Rating", ratingSchema);