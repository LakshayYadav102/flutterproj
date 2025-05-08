const mongoose = require("mongoose");

const DonationSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  amount: { type: Number, required: true }, // Amount donated
  treesSponsored: { type: Number, required: true }, // Trees funded by user
  transactionId: { type: String, required: true }, // Transaction ID for payment
  date: { type: Date, default: Date.now }
});

module.exports = mongoose.models.Donation || mongoose.model("Donation", DonationSchema);