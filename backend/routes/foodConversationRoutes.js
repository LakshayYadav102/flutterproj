const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const FoodConversation = require("../models/FoodConversation");
const FoodDonation = require("../models/FoodDonation");

const verifyToken = (req, res, next) => {
  const token = req.header("Authorization");
  if (!token || !token.startsWith("Bearer ")) {
    return res.status(401).json({ message: "No token, authorization denied" });
  }
  try {
    const decoded = jwt.verify(token.split(" ")[1], process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
};

/* START OR GET CONVERSATION - NOW RETURNS POPULATED DATA */
router.post("/start", verifyToken, async (req, res) => {
  try {
    const { donationId } = req.body;
    const donation = await FoodDonation.findById(donationId);

    if (!donation || donation.status !== "ACCEPTED") {
      return res.status(400).json({ message: "Invalid donation" });
    }

    if (
      donation.donor.toString() !== req.userId &&
      donation.acceptedBy?.toString() !== req.userId
    ) {
      return res.status(403).json({ message: "Not authorized" });
    }

    let conversation = await FoodConversation.findOne({ donation: donationId });

    if (!conversation) {
      conversation = await FoodConversation.create({
        donor: donation.donor,
        receiver: donation.acceptedBy,
        donation: donationId,
        messages: [],
      });
    }

    // Return populated version
    const populated = await FoodConversation.findById(conversation._id)
      .populate("donor", "username")
      .populate("receiver", "username")
      .populate("messages.sender", "username");

    res.json(populated);
  } catch (error) {
    console.error("Start Conversation Error:", error);
    res.status(500).json({ message: "Failed to start conversation" });
  }
});

/**
 * SEND MESSAGE
 * POST /api/food-conversations/:id/message
 */
router.post("/:id/message", verifyToken, async (req, res) => {
  try {
    const { message } = req.body;

    const conversation = await FoodConversation.findById(req.params.id);

    if (!conversation) {
      return res.status(404).json({ message: "Conversation not found" });
    }

    // Only donor or receiver can send message
    if (
      conversation.donor.toString() !== req.userId &&
      conversation.receiver.toString() !== req.userId
    ) {
      return res.status(403).json({ message: "Not authorized" });
    }

    conversation.messages.push({
      sender: req.userId,
      message,
    });

    await conversation.save();

    res.json({ message: "Message sent", conversation });
  } catch (error) {
    console.error("Send Message Error:", error);
    res.status(500).json({ message: "Failed to send message" });
  }
});

/**
 * GET CONVERSATION
 * GET /api/food-conversations/:id
 */
router.get("/:id", verifyToken, async (req, res) => {
  try {
    const conversation = await FoodConversation.findById(req.params.id)
      .populate("donor", "username")
      .populate("receiver", "username")
      .populate("messages.sender", "username");

    if (!conversation) {
      return res.status(404).json({ message: "Conversation not found" });
    }

    if (
      conversation.donor._id.toString() !== req.userId &&
      conversation.receiver._id.toString() !== req.userId
    ) {
      return res.status(403).json({ message: "Not authorized" });
    }

    res.json(conversation);
  } catch (error) {
    console.error("Get Conversation Error:", error);
    res.status(500).json({ message: "Failed to fetch conversation" });
  }
});

module.exports = router;