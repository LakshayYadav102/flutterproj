const mongoose = require("mongoose");

const commentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },
  text: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const ecoVideoSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },

  videoUrl: {
    type: String,
    required: true
  },

  caption: {
    type: String,
    required: true
  },

  category: {
    type: String,
    enum: ["Waste", "Energy", "Climate", "Food", "DIY", "Travel"],
    required: true
  },

  likes: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    }
  ],

  comments: [commentSchema],

  views: {
    type: Number,
    default: 0
  },

  status: {
    type: String,
    enum: ["pending", "approved"],
    default: "pending"
  }

}, { timestamps: true });

module.exports =
  mongoose.models.EcoVideo ||
  mongoose.model("EcoVideo", ecoVideoSchema);