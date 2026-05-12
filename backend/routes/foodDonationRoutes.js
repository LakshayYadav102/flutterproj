const express = require("express");
const router = express.Router();
const FoodDonation = require("../models/FoodDonation");
const User = require("../models/user"); 
const jwt = require("jsonwebtoken");

// Middleware
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

/* ====================== CREATE ====================== */
router.post("/", verifyToken, async (req, res) => {
  try {
    let { quantity, unit } = req.body;
    quantity = Number(quantity);

    if (!quantity || quantity <= 0) {
      return res.status(400).json({ message: "Invalid quantity provided" });
    }

    let quantityInKg = 0;
    if (unit === "kg") quantityInKg = quantity;
    else if (unit === "grams") quantityInKg = quantity / 1000;
    else if (unit === "plates") quantityInKg = quantity * 0.4;
    else return res.status(400).json({ message: "Invalid unit" });

    const carbonSaved = Number((quantityInKg * 2.5).toFixed(2));

    const donation = new FoodDonation({
      donor: req.userId,
      donationSource: req.body.donationSource,
      eventType: req.body.eventType || "",
      eventName: req.body.eventName || "",
      foodCategory: req.body.foodCategory,
      foodType: req.body.foodType,
      quantity,
      unit,
      expiryTime: req.body.expiryTime,
      location: req.body.location,
      notes: req.body.notes || "",
      contactPerson: req.body.contactPerson || "",
      contactNumber: req.body.contactNumber || "",
      carbonSaved,
      // 🟢 THE FIX: You MUST include expiredHandling here so Mongoose receives it!
      expiredHandling: req.body.expiredHandling || "COMPOST", 
    });

    await donation.save();
    res.status(201).json(donation);
  } catch (error) {
    console.error("Create Food Donation Error:", error);
    res.status(500).json({ message: "Failed to create food donation" });
  }
});

/* ====================== AVAILABLE FOOD ====================== */
router.get("/available", verifyToken, async (req, res) => {
  try {
    const availableFood = await FoodDonation.find({
      status: "AVAILABLE",
      expiryTime: { $gt: new Date() },
      donor: { $ne: req.userId },
    })
      .populate("donor", "username email")
      .sort({ expiryTime: 1 });

    res.json(availableFood);
  } catch (error) {
    console.error("Get Available Food Error:", error);
    res.status(500).json({ message: "Failed to fetch available food" });
  }
});

/* ====================== MY DONATIONS ====================== */
router.get("/my", verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select("username email profilePic role");

    const donations = await FoodDonation.find({ donor: req.userId })
      .sort({ createdAt: -1 });

    let totalCarbonSaved = 0;
    let totalQuantityInKg = 0;

    donations.forEach((d) => {
      let carbon = d.carbonSaved;
      if (carbon == null || carbon === 0) {
        let kg = d.quantity;
        if (d.unit === "grams") kg /= 1000;
        if (d.unit === "plates") kg *= 0.4;
        carbon = Number((kg * 2.5).toFixed(2));
      }
      totalCarbonSaved += carbon || 0;

      let qtyKg = d.quantity;
      if (d.unit === "grams") qtyKg /= 1000;
      if (d.unit === "plates") qtyKg *= 0.4;
      totalQuantityInKg += qtyKg;
    });

    res.json({
      user, 
      summary: {
        totalDonations: donations.length,
        totalCarbonSaved: Number(totalCarbonSaved.toFixed(2)),
        totalFoodDonatedKg: Number(totalQuantityInKg.toFixed(2)),
      },
      donations,
    });
  } catch (error) {
    console.error("Get My Donations Error:", error);
    res.status(500).json({ message: "Failed to fetch donation history" });
  }
});

/* ====================== RECEIVED ====================== */
router.get("/received", verifyToken, async (req, res) => {
  try {
    const received = await FoodDonation.find({
      acceptedBy: req.userId,
      status: "ACCEPTED",
    })
      .populate("donor", "username email")
      .sort({ updatedAt: -1 });

    let totalFoodReceivedKg = 0;
    let totalCarbonImpact = 0;

    received.forEach((d) => {
      let carbon = d.carbonSaved;
      if (carbon == null || carbon === 0) {
        let kg = d.quantity;
        if (d.unit === "grams") kg /= 1000;
        if (d.unit === "plates") kg *= 0.4;
        carbon = Number((kg * 2.5).toFixed(2));
      }
      totalCarbonImpact += carbon || 0;

      let qtyKg = d.quantity;
      if (d.unit === "grams") qtyKg /= 1000;
      if (d.unit === "plates") qtyKg *= 0.4;
      totalFoodReceivedKg += qtyKg;
    });

    res.json({
      summary: {
        totalReceived: received.length,
        totalFoodReceivedKg: Number(totalFoodReceivedKg.toFixed(2)),
        totalCarbonImpact: Number(totalCarbonImpact.toFixed(2)),
      },
      received,
    });
  } catch (error) {
    console.error("Get Received Food Error:", error);
    res.status(500).json({ message: "Failed to fetch received food" });
  }
});

/* ====================== ACCEPT & EXPIRE ====================== */
router.patch("/:id/accept", verifyToken, async (req, res) => {
  try {
    const donation = await FoodDonation.findById(req.params.id);
    if (!donation) return res.status(404).json({ message: "Donation not found" });

    if (donation.status !== "AVAILABLE") {
      return res.status(400).json({ message: "Food is no longer available" });
    }

    if (donation.expiryTime < new Date()) {
      donation.status = "EXPIRED";
      donation.expiredHandling = donation.foodCategory === "raw" ? "COMPOST" : "ANIMAL_FEED";
      await donation.save();
      return res.status(400).json({ message: "Food has already expired" });
    }

    donation.status = "ACCEPTED";
    donation.acceptedBy = req.userId;
    await donation.save();

    // Gamification: Reward GreenCoins to the DONOR
    const coinsEarned = Math.max(1, Math.round((donation.carbonSaved || 0) / 5));
    
    try {
      await User.findByIdAndUpdate(
        donation.donor,
        { $inc: { greenCoins: coinsEarned } }
      );
      console.log(`🎉 Awarded ${coinsEarned} GreenCoins to donor ${donation.donor} for rescuing food!`);
    } catch (rewardError) {
      console.error("Failed to award GreenCoins to donor:", rewardError);
    }

    res.json({ message: "Food accepted successfully", donation, coinsEarned });
  } catch (error) {
    console.error("Accept Food Error:", error);
    res.status(500).json({ message: "Failed to accept food" });
  }
});

router.patch("/:id/expire", async (req, res) => {
  try {
    const donation = await FoodDonation.findById(req.params.id);
    if (!donation) return res.status(404).json({ message: "Donation not found" });
    if (donation.status !== "AVAILABLE") {
      return res.status(400).json({ message: "Cannot expire this donation" });
    }

    donation.status = "EXPIRED";
    donation.expiredHandling = donation.foodCategory === "raw" ? "COMPOST" : "ANIMAL_FEED";
    await donation.save();

    res.json({ message: "Donation expired", donation });
  } catch (error) {
    console.error("Expire Food Error:", error);
    res.status(500).json({ message: "Failed to expire donation" });
  }
});

module.exports = router;