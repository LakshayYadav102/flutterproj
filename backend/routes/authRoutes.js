const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// ✅ Register Route (Fixed `name` field)
router.post('/register', async (req, res) => {
  console.log("Received Registration Data:", req.body);
  const { name, username, email, password } = req.body; // ✅ Fixed: Changed `fullName` to `name`

  try {
    if (!name || !username || !email || !password) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
      console.error(`Email already in use: ${email}`);
      return res.status(400).json({ message: 'Email already in use' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({ name, username, email, password: hashedPassword }); // ✅ Updated to `name`
    await newUser.save();

    console.log(`User registered successfully: ${username} (${email})`);
    res.status(201).json({ message: 'User registered successfully!' });
  } catch (err) {
    console.error('Error in Register Route:', err);
    res.status(500).json({ message: 'Server error. Please try again later.' });
  }
});

// ✅ Login Route
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    console.log('Login Request Body:', req.body);

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      console.error(`User not found with email: ${email}`);
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    console.log('User Found in DB:', user);

    const isMatch = await bcrypt.compare(password, user.password);
    console.log('Password Match:', isMatch);

    if (!isMatch) {
      console.error('Invalid password attempt for:', email);
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    if (!process.env.JWT_SECRET) {
      console.error('JWT_SECRET is missing in environment variables');
      return res.status(500).json({ message: 'Server configuration error' });
    }

    const token = jwt.sign(
      { userId: user._id, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    console.log('JWT Generated:', token);

    res.status(200).json({ token, userId: user._id, username: user.username, email: user.email });
  } catch (err) {
    console.error('Error in Login Route:', err);
    res.status(500).json({ message: 'Server error. Please try again later.' });
  }
});

module.exports = router;
