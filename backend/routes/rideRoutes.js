// routes/rideRoutes.js
const express = require("express");
const router = express.Router();
const Ride = require("../models/Ride");
const Booking = require("../models/Booking");
const RideRequest = require("../models/RideRequest");
const Rating = require("../models/Rating");
const User = require("../models/user"); 
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");

// 🔐 Inline JWT Verification
const verifyToken = (req, res, next) => {
  const token = req.header("Authorization");
  if (!token) return res.status(401).json({ message: "Access Denied. No token provided." });

  try {
    const decoded = jwt.verify(token.split(" ")[1], process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(403).json({ message: "Invalid or expired token" });
  }
};

// ============================
// Post Ride Request
// ============================
router.post("/request", verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(400).json({ error: "User not found" });

    const { from, to, date, time, seatsNeeded } = req.body;
    if (!from || !to || !date || !time || !seatsNeeded) {
      return res.status(400).json({ error: "Missing required fields" });
    }
    if (seatsNeeded < 1) {
      return res.status(400).json({ error: "Seats needed must be at least 1" });
    }

    const request = new RideRequest({
      ...req.body,
      requester: req.userId,
      status: "open",
    });
    const savedRequest = await request.save();

    res.status(201).json({ message: "Ride request posted successfully", request: savedRequest });
  } catch (err) {
    res.status(500).json({ error: "Server error while posting ride request", details: err.message });
  }
});

// ============================
// Get Ride Requests
// ============================
router.get("/requests", verifyToken, async (req, res) => {
  try {
    const isValidHex = /^[0-9a-fA-F]{24}$/.test(req.userId);
    if (!isValidHex) return res.status(400).json({ error: "Invalid user ID format" });

    let userIdObj;
    try {
      userIdObj = new mongoose.Types.ObjectId(req.userId);
    } catch (err) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    const { myRequests } = req.query;
    const query = myRequests === "true"
      ? { requester: userIdObj, status: { $in: ["open", "matched"] } }
      : { status: "open" };

    const requests = await RideRequest.find(query)
      .populate("requester", "username email")
      .populate("matchedRide")
      .sort({ createdAt: -1 })
      .lean();

    const transformedRequests = requests.map((request) => ({
      ...request,
      // ✅ FIX: Included the _id so the frontend can filter out the user's own requests
      requester: request.requester 
        ? { _id: request.requester._id, name: request.requester.username, email: request.requester.email } 
        : { _id: null, name: "Unknown", email: "N/A" },
    }));

    res.json(transformedRequests);
  } catch (err) {
    res.status(500).json({ error: "Server error while fetching ride requests", details: err.message });
  }
});

// ============================
// Cancel Ride Request
// ============================
router.post("/request/:requestId/cancel", verifyToken, async (req, res) => {
  try {
    const request = await RideRequest.findById(req.params.requestId);
    if (!request) return res.status(404).json({ error: "Ride request not found" });

    if (request.requester.toString() !== req.userId) {
      return res.status(403).json({ error: "Only the requester can cancel this request" });
    }

    if (request.status === "cancelled") {
      return res.status(400).json({ error: "Request is already cancelled" });
    }

    request.status = "cancelled";
    await request.save();

    res.json({ message: "Ride request cancelled successfully" });
  } catch (err) {
    res.status(500).json({ error: "Server error while cancelling ride request", details: err.message });
  }
});

// ============================
// Offer a Ride (Create Ride) & AWARD COINS
// ============================
router.post("/offer", verifyToken, async (req, res) => {
  try {
    const { vehicle, from, to, date, time, seatsAvailable, pricePerSeat, distance, estimatedDuration, stops, luggageSpace, smokingAllowed, petsAllowed, additionalNotes, carbonOffset, matchedRequest } = req.body;

    const driver = await User.findById(req.userId);
    if (!driver) return res.status(400).json({ error: "Invalid driver ID" });

    if (!vehicle || !vehicle.make || !vehicle.model || !vehicle.licensePlate || !vehicle.carType || !vehicle.totalSeats || !vehicle.fuelType) {
      return res.status(400).json({ error: "All vehicle fields are required" });
    }
    if (!from || !to || !date || !time || !seatsAvailable || pricePerSeat === undefined) {
      return res.status(400).json({ error: "All trip fields are required" });
    }
    if (seatsAvailable > vehicle.totalSeats) {
      return res.status(400).json({ error: "Seats available cannot exceed total seats" });
    }

    const ride = new Ride({
      driver: req.userId,
      vehicle,
      from,
      to,
      date,
      time,
      seatsAvailable,
      pricePerSeat,
      distance,
      estimatedDuration,
      stops: stops || [],
      luggageSpace: luggageSpace || "None",
      smokingAllowed: !!smokingAllowed,
      petsAllowed: !!petsAllowed,
      additionalNotes,
      carbonOffset: !!carbonOffset,
      matchedRequest: matchedRequest || null,
      messages: []
    });

// ... existing code in POST /offer ...
    await ride.save();

    // Gamification: Reward Driver 2 GreenCoins
    try {
      await User.findByIdAndUpdate(req.userId, { $inc: { greenCoins: 2 } });
      console.log(`🎉 Awarded 2 GreenCoins to driver ${req.userId} for offering a ride!`);
    } catch (rewardError) {
      console.error("Failed to award coins for offering ride:", rewardError);
    }

    // ✅ THE FIX: Auto-create a Booking for the passenger who made the request
    if (matchedRequest) {
      const request = await RideRequest.findById(matchedRequest);
      if (request && request.status === "open") {
        // Update request status
        request.status = "matched";
        request.matchedRide = ride._id;
        await request.save();

        // Create a confirmed booking for the passenger
        const autoBooking = new Booking({
          ride: ride._id,
          passenger: request.requester,
          seatsBooked: request.seatsNeeded,
          paymentMethod: "Cash", // Default or mutual agreement
          status: "confirmed"
        });
        await autoBooking.save();

        // Add the passenger to the ride and reduce available seats
        ride.passengers.push(request.requester);
        ride.seatsAvailable -= request.seatsNeeded;
        await ride.save();
      }
    }

    res.status(201).json({ message: "Ride offered successfully! You earned 2 GreenCoins.", ride });
  } catch (err) {
    res.status(500).json({ error: "Server error while offering ride", details: err.message });
  }
});

// ... (The rest of your routes remain exactly the same) ...

// ============================
// Update Ride (PATCH by Driver)
// ============================
router.patch("/:id", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) return res.status(404).json({ error: "Ride not found" });
    if (ride.driver.toString() !== req.userId) return res.status(403).json({ error: "Only driver can edit" });

    const confirmedBookings = await Booking.countDocuments({ ride: ride._id, status: "confirmed" });
    if (confirmedBookings > 0) return res.status(400).json({ error: "Cannot edit ride with confirmed bookings" });

    const updatedRide = await Ride.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ message: "Ride updated successfully", ride: updatedRide });
  } catch (err) {
    res.status(500).json({ error: "Server error while updating ride", details: err.message });
  }
});

// ============================
// Find Rides (Search Rides with Filters)
// ============================
router.get("/find", verifyToken, async (req, res) => {
  try {
    const { from, to, date, priceMin, priceMax, vehicleType, petsAllowed, smokingAllowed, luggageSpace } = req.query;

    const query = { seatsAvailable: { $gt: 0 }, status: "upcoming" };
    if (from) query.from = { $regex: from, $options: "i" };
    if (to) query.to = { $regex: to, $options: "i" };
    if (date) query.date = new Date(date);
    if (priceMin || priceMax) query.pricePerSeat = {};
    if (priceMin) query.pricePerSeat.$gte = Number(priceMin);
    if (priceMax) query.pricePerSeat.$lte = Number(priceMax);
    if (vehicleType) query["vehicle.carType"] = vehicleType;
    if (petsAllowed) query.petsAllowed = petsAllowed === 'true';
    if (smokingAllowed) query.smokingAllowed = smokingAllowed === 'true';
    if (luggageSpace) query.luggageSpace = luggageSpace;

    const rides = await Ride.find(query)
      .populate({ path: "driver", select: "username email" })
      .lean();

    const validRides = rides.map((ride) => ({
      ...ride,
      driver: ride.driver ? { name: ride.driver.username, email: ride.driver.email } : { name: "Unknown", email: "N/A" }
    }));

    res.json(validRides);
  } catch (err) {
    res.status(500).json({ error: "Server error while fetching rides", details: err.message });
  }
});

// ============================
// Get User's Rides (My Trips)
// ============================
router.get("/mytrips", verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(400).json({ error: "User not found" });

    let ridesOffered = await Ride.find({ driver: req.userId })
      .populate("driver", "username email")
      .populate("passengers", "username email")
      .lean();

    for (let ride of ridesOffered) {
      ride.bookings = await Booking.find({ ride: ride._id })
        .populate("passenger", "username email")
        .lean();
    }

    const bookings = await Booking.find({ passenger: req.userId })
      .populate({
        path: "ride",
        populate: { path: "driver", select: "username email" }
      })
      .lean();

    const validRidesOffered = ridesOffered.map((ride) => ({
      ...ride,
      driver: ride.driver ? { name: ride.driver.username, email: ride.driver.email } : { name: "Unknown", email: "N/A" },
      passengers: ride.passengers?.map((p) => ({ ...p, name: p.username || "Unknown", email: p.email || "N/A" })) || [],
      bookings: ride.bookings || []
    }));

    const validBookings = bookings.map((booking) => ({
      ...booking,
      ride: booking.ride ? {
        ...booking.ride,
        driver: booking.ride.driver ? { name: booking.ride.driver.username, email: booking.ride.driver.email } : { name: "Unknown", email: "N/A" }
      } : null
    })).filter((booking) => booking.ride);

    res.json({ ridesOffered: validRidesOffered, bookings: validBookings });
  } catch (err) {
    res.status(500).json({ error: "Server error while fetching trips", details: err.message });
  }
});

// ============================
// Get Ride Details
// ============================
router.get("/:id", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id)
      .populate("driver", "username email")
      .populate("passengers", "username email")
      .populate({ path: "messages.sender", select: "username" });

    if (!ride) return res.status(404).json({ error: "Ride not found" });

    const isDriver = ride.driver._id.toString() === req.userId;
    let userBooking = null;
    if (!isDriver) {
      userBooking = await Booking.findOne({ ride: req.params.id, passenger: req.userId })
        .populate("passenger", "username email")
        .lean();
    }

    const transformedRide = {
      ...ride.toObject(),
      driverId: ride.driver ? ride.driver._id.toString() : null,
      driver: ride.driver ? { name: ride.driver.username, email: ride.driver.email } : { name: "Unknown", email: "N/A" },
      passengers: ride.passengers?.map((p) => ({ ...p.toObject(), name: p.username || "Unknown", email: p.email || "N/A" })) || [],
      messages: ride.messages.map((msg) => ({ ...msg.toObject(), sender: { _id: msg.sender._id, name: msg.sender.username || "Unknown" } })),
      userBooking: userBooking
    };

    res.json(transformedRide);
  } catch (err) {
    res.status(500).json({ error: "Server error while fetching ride details", details: err.message });
  }
});

// ============================
// Get Bookings for Ride (for Driver)
// ============================
router.get("/:rideId/bookings", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.rideId);
    if (!ride) return res.status(404).json({ error: "Ride not found" });
    if (ride.driver.toString() !== req.userId) return res.status(403).json({ error: "Unauthorized" });
    
    const bookings = await Booking.find({ ride: req.params.rideId }).populate("passenger", "username email");
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ error: "Server error while fetching bookings", details: err.message });
  }
});

// ============================
// Book a Ride
// ============================
router.post("/book/:rideId", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.rideId);
    if (!ride) return res.status(404).json({ error: "Ride not found" });

    if (ride.driver.toString() === req.userId) {
      return res.status(400).json({ error: "You cannot book your own ride" });
    }
    if (ride.status !== "upcoming") {
      return res.status(400).json({ error: "Ride is not available for booking" });
    }

    const { seatsBooked, paymentMethod } = req.body;
    if (!seatsBooked || seatsBooked < 1) return res.status(400).json({ error: "Invalid number of seats booked" });
    if (ride.seatsAvailable < seatsBooked) return res.status(400).json({ error: "Not enough seats available" });

    const booking = new Booking({
      ride: ride._id,
      passenger: req.userId,
      seatsBooked,
      paymentMethod
    });

    await booking.save();
    res.status(201).json({ message: "Booking request sent successfully", booking });
  } catch (err) {
    res.status(500).json({ error: "Server error while booking ride", details: err.message });
  }
});

// ============================
// Update Booking Status (Confirm/Reject) & AWARD COINS
// ============================
router.post("/book/:bookingId/status", verifyToken, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.bookingId).populate("ride");
    if (!booking) return res.status(404).json({ error: "Booking not found" });

    if (booking.ride.driver.toString() !== req.userId) {
      return res.status(403).json({ error: "Only the driver can update booking status" });
    }

    const { status, reason } = req.body;
    if (!["confirmed", "rejected"].includes(status)) return res.status(400).json({ error: "Invalid status" });
    if (booking.status !== "pending") return res.status(400).json({ error: "Booking is not pending" });

    if (status === "confirmed") {
      if (booking.ride.seatsAvailable < booking.seatsBooked) {
        return res.status(400).json({ error: "Not enough seats available for confirmation" });
      }
      booking.ride.seatsAvailable -= booking.seatsBooked;
      booking.ride.passengers.push(booking.passenger);
      await booking.ride.save();

      // 🟢 Gamification: Reward Passenger 2 GreenCoins for sharing a ride
      try {
        await User.findByIdAndUpdate(booking.passenger, { $inc: { greenCoins: 2 } });
        console.log(`🎉 Awarded 2 GreenCoins to passenger ${booking.passenger} for a confirmed booking!`);
      } catch (rewardError) {
        console.error("Failed to award coins for booking:", rewardError);
      }
    } else if (status === "rejected") {
      booking.cancellationReason = reason;
    }

    booking.status = status;
    await booking.save();

    res.json({ message: "Booking status updated", booking });
  } catch (err) {
    res.status(500).json({ error: "Server error while updating booking status", details: err.message });
  }
});

// ============================
// Cancel Booking
// ============================
router.post("/book/:bookingId/cancel", verifyToken, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.bookingId).populate("ride");
    if (!booking) return res.status(404).json({ error: "Booking not found" });

    if (booking.passenger.toString() !== req.userId && booking.ride.driver.toString() !== req.userId) {
      return res.status(403).json({ error: "Only passenger or driver can cancel" });
    }

    if (booking.status === "rejected" || booking.status === "cancelled") {
      return res.status(400).json({ error: "Booking is already cancelled or rejected" });
    }

    const { reason } = req.body;

    if (booking.status === "confirmed") {
      booking.ride.seatsAvailable += booking.seatsBooked;
      booking.ride.passengers = booking.ride.passengers.filter(p => p.toString() !== booking.passenger.toString());
      await booking.ride.save();
    }

    booking.status = "cancelled";
    booking.cancellationReason = reason;
    await booking.save();

    res.json({ message: "Booking cancelled successfully", booking });
  } catch (err) {
    res.status(500).json({ error: "Server error while cancelling booking", details: err.message });
  }
});

// ============================
// Post Rating
// ============================
router.post("/ratings", verifyToken, async (req, res) => {
  try {
    const { rideId, revieweeId, rating, review } = req.body;

    const ride = await Ride.findById(rideId);
    if (!ride) return res.status(404).json({ error: "Ride not found" });
    if (ride.status !== "completed") return res.status(400).json({ error: "Can only rate completed rides" });

    const isDriver = ride.driver.toString() === req.userId;
    const isPassenger = ride.passengers.some(p => p.toString() === req.userId);
    if (!isDriver && !isPassenger) return res.status(403).json({ error: "Only participants can rate" });

    if (req.userId === revieweeId) return res.status(400).json({ error: "Cannot rate yourself" });

    const existing = await Rating.findOne({ ride: rideId, reviewer: req.userId, reviewee: revieweeId });
    if (existing) return res.status(400).json({ error: "Already rated this user for this ride" });

    const ratingDoc = new Rating({
      ride: rideId,
      reviewer: req.userId,
      reviewee: revieweeId,
      rating,
      review
    });
    await ratingDoc.save();
    res.status(201).json({ message: "Rating submitted", rating: ratingDoc });
  } catch (err) {
    res.status(500).json({ error: "Server error while submitting rating", details: err.message });
  }
});

// ============================
// Get Ratings for User
// ============================
router.get("/ratings/user/:userId", verifyToken, async (req, res) => {
  try {
    const ratings = await Rating.find({ reviewee: req.params.userId }).populate("reviewer", "username");
    res.json(ratings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================
// Cancel Ride (by Driver)
// ============================
router.post("/:rideId/cancel", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.rideId);
    if (!ride) return res.status(404).json({ error: "Ride not found" });

    if (ride.driver.toString() !== req.userId) {
      return res.status(403).json({ error: "Only the driver can cancel this ride" });
    }

    const { reason } = req.body;
    await Booking.updateMany({ ride: ride._id }, { status: "cancelled", cancellationReason: reason || "Ride cancelled by driver" });

    ride.status = "cancelled";
    await ride.save();

    res.json({ message: "Ride cancelled successfully" });
  } catch (err) {
    res.status(500).json({ error: "Server error while cancelling ride", details: err.message });
  }
});

module.exports = router;