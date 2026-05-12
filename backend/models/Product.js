const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true }, // Price in Rupees
  image: { type: String, required: true },
  category: { type: String, default: "General" },
  stock: { type: Number, default: 100 }
}, { timestamps: true });

module.exports = mongoose.models.Product || mongoose.model("Product", productSchema);