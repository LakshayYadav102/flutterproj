// const express = require('express');
// const router = express.Router();

// const Ride = require('../models/Ride');
// const Booking = require('../models/Booking');
// const Review = require('../models/Review');

// const jwt = require("jsonwebtoken");

// // Inline auth middleware
// const authMiddleware = (req, res, next) => {
//   const token =
//     req.headers.authorization?.split(" ")[1] ||
//     req.query.token;

//   if (!token) return res.status(401).json({ error: "Unauthorized" });

//   try {
//     const decoded = jwt.verify(token, process.env.JWT_SECRET);
//     req.user = decoded;
//     next();
//   } catch (err) {
//     return res.status(401).json({ error: "Invalid token" });
//   }
// };


// // =============== RIDE ROUTES =============== //

// // Create Ride
// router.post('/rides', async (req, res) => {
//   try {
//     const newRide = await Ride.create(req.body);
//     res.status(201).json(newRide);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // Get all rides / search
// router.get('/rides', async (req, res) => {
//   try {
//     const { origin, destination, date } = req.query;
//     const query = {};
//     if (origin) query.origin = new RegExp(origin, 'i');
//     if (destination) query.destination = new RegExp(destination, 'i');
//     if (date) query.date = { $gte: new Date(date) };

//     const rides = await Ride.find(query); // ❌ removed populate
//     res.json(rides);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // Offer a ride (driverId comes from token)
// router.post('/rides', authMiddleware, async (req, res) => {
//   try {
//     req.body.driverId = req.user.id; // set driver ID from token
//     const newRide = await Ride.create(req.body);
//     res.status(201).json(newRide);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });


// // Get ride by ID
// router.get('/rides/:id', async (req, res) => {
//   try {
//     const ride = await Ride.findById(req.params.id); // ❌ removed populate
//     if (!ride) return res.status(404).json({ error: 'Ride not found' });
//     res.json(ride);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // =============== BOOKING ROUTES =============== //

// // Request booking
// router.post('/bookings', async (req, res) => {
//   try {
//     const booking = await Booking.create(req.body);
//     res.status(201).json(booking);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // Update booking status
// const mongoose = require('mongoose');

// router.put('/bookings/:id', async (req, res) => {
//   const { id } = req.params;
//   const { status } = req.body;

//   if (!mongoose.Types.ObjectId.isValid(id)) {
//     return res.status(400).json({ error: 'Invalid booking ID' });
//   }

//   try {
//     const booking = await Booking.findByIdAndUpdate(
//       id,
//       { status },
//       { new: true }
//     );

//     if (!booking) {
//       return res.status(404).json({ error: 'Booking not found' });
//     }

//     res.status(200).json(booking);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });



// // Get all bookings of a user
// router.get('/bookings/user/:userId', async (req, res) => {
//   try {
//     const ridesOffered = await Ride.find({ driverId: req.params.userId });
//     const ridesBooked = await Booking.find({ passengerId: req.params.userId });
//     res.json({ ridesOffered, ridesBooked });
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // =============== REVIEW ROUTES =============== //

// // Add review
// router.post('/reviews', async (req, res) => {
//   try {
//     const review = await Review.create(req.body);
//     res.status(201).json(review);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// // Get reviews for a user
// router.get('/reviews/:userId', async (req, res) => {
//   try {
//     const reviews = await Review.find({ reviewedUserId: req.params.userId });
//     res.json(reviews);
//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// module.exports = router;
