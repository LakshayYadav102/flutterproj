const mongoose = require("mongoose");

const donationSchema = new mongoose.Schema({
  amount: Number,          // 💰 Total amount donated
  treesPlanted: Number,    // 🌳 Number of trees user paid for
  date: { type: Date, default: Date.now }
});

const UserSchema = new mongoose.Schema({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true }, // Password should be hashed
  totalCarbonFootprint: { type: Number, default: 0 }, // Lifetime carbon footprint
  
  // 🟢 NEW: GreenCoin Wallet Balance
  greenCoins: { type: Number, default: 0 }, 
  
  mobile: { type: String, default: "" },
  dob: { type: Date, default: null },
  address: { type: String, default: "" },
  profilePic: { type: String, default: "" },
  role: { type: String, enum: ["user", "admin", "corporate"], default: "user" },
  companyName: { type: String, default: "" }, // 🏢 NEW: Store company name for B2B dashboard
  donations: [donationSchema], // 🌱 Track donation history

  // Added social graph fields (followers & following)
  followers: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    }
  ],

  following: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    }
  ]
}, {
  timestamps: true   
});

module.exports = mongoose.models.User || mongoose.model("User", UserSchema);