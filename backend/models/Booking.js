const mongoose = require("mongoose");

const bookingSchema = new mongoose.Schema({
  ride: { type: mongoose.Schema.Types.ObjectId, ref: "Ride", required: true },
  passenger: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  status: { type: String, enum: ["pending", "confirmed", "rejected", "cancelled"], default: "pending" },
  seatsBooked: { type: Number, min: 1, default: 1 },
  paymentMethod: { type: String, enum: ["cash", "online"], default: "cash" },
  cancellationReason: { type: String }
}, { timestamps: true });

// Add index for faster queries on passenger and ride
bookingSchema.index({ passenger: 1 });
bookingSchema.index({ ride: 1 });

module.exports = mongoose.model("Booking", bookingSchema);