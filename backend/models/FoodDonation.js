const mongoose = require("mongoose");

const FoodDonationSchema = new mongoose.Schema(
  {
    donor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    donationSource: {
      type: String,
      enum: ["HOUSEHOLD", "EVENT"],
      required: true,
    },
    eventType: { type: String, default: "" },
    eventName: { type: String, default: "" },

    foodCategory: {
      type: String,
      enum: ["cooked", "raw", "packaged"],
      required: true,
    },
    foodType: {
      type: String,
      enum: ["veg", "non-veg", "mixed"],
      required: true,
    },
    quantity: { type: Number, required: true },
    unit: {
      type: String,
      enum: ["kg", "grams", "plates"],
      required: true,
    },

    expiryTime: { type: Date, required: true },
    location: { type: String, required: true },
    notes: { type: String, default: "" },

    // Added from EventDonationForm
    contactPerson: { type: String, default: "" },
    contactNumber: { type: String, default: "" },

    carbonSaved: {
      type: Number,
      default: 0,
    },

    status: {
      type: String,
      enum: ["AVAILABLE", "ACCEPTED", "EXPIRED"],
      default: "AVAILABLE",
    },
    acceptedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    expiredHandling: {
      type: String,
      enum: ["COMPOST", "ANIMAL_FEED", "SAFE_DISPOSAL"],
      default: null,
    },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.FoodDonation ||
  mongoose.model("FoodDonation", FoodDonationSchema);