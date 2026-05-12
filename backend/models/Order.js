const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
  originalPrice: { type: Number, required: true },
  coinsUsed: { type: Number, default: 0 },
  finalAmountPaid: { type: Number, required: true },
  shippingAddress: { type: String, required: true },
  status: { type: String, default: "Processing" }, // Processing, Shipped, Delivered
}, { timestamps: true });

module.exports = mongoose.models.Order || mongoose.model("Order", orderSchema);