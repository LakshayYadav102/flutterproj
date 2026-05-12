// models/RideRequest.js
const mongoose = require("mongoose");

const rideRequestSchema = new mongoose.Schema(
  {
    requester: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    from: { type: String, required: true },
    to: { type: String, required: true },
    date: { type: Date, required: true },
    time: { type: String, required: true },
    seatsNeeded: { type: Number, required: true },
    additionalNotes: { type: String },
    status: {
      type: String,
      enum: ["open", "matched", "cancelled"],
      default: "open",
    },
    matchedRide: { type: mongoose.Schema.Types.ObjectId, ref: "Ride" },
  },
  {
    timestamps: true,
    collection: "riderequests", // Explicitly specify the collection name
  }
);

rideRequestSchema.index({ requester: 1 });
rideRequestSchema.index({ from: 1, to: 1, date: 1 });

module.exports = mongoose.model("RideRequest", rideRequestSchema);