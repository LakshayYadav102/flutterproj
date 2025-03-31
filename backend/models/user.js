const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  username: { type: String, required: true }, // ✅ REQUIRED
  name: { type: String, required: true }, // ✅ ADDED name field
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true }, // Password should be hashed
  totalCarbonFootprint: { type: Number, default: 0 }, // 🌱 Carbon Footprint
  mobile: { type: String, default: "" }, // 📱 Mobile Number
  dob: { type: Date, default: null }, // 📅 Date of Birth
  address: { type: String, default: "" }, // 🏠 Address
  profilePic: { type: String, default: "" }, // 🖼 Profile Picture (file path)
});

// ✅ Prevents re-compiling the model if it already exists
module.exports = mongoose.models.User || mongoose.model("User", UserSchema);
