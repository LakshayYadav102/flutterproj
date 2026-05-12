const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const Order = require('../models/Order');
const User = require('../models/user');
const jwt = require('jsonwebtoken');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const verifyToken = (req, res, next) => {
  const token = req.header("Authorization");
  if (!token || !token.startsWith("Bearer ")) {
    return res.status(401).json({ message: "No token" });
  }
  try {
    const decoded = jwt.verify(token.split(" ")[1], process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    res.status(401).json({ message: "Invalid token" });
  }
};

// 1. Fetch all products
router.get('/products', async (req, res) => {
  try {
    const products = await Product.find();
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch products" });
  }
});

// 2. Create Stripe Payment Intent
router.post('/create-payment-intent', verifyToken, async (req, res) => {
  try {
    const { productId, coinsToUse } = req.body;
    const user = await User.findById(req.userId);
    const product = await Product.findById(productId);

    if (!user || !product) return res.status(404).json({ error: "User or Product not found" });
    if (product.stock < 1) return res.status(400).json({ error: "Product out of stock" });
    if (coinsToUse > user.greenCoins) return res.status(400).json({ error: "Insufficient GreenCoins" });

    const actualCoinsUsed = Math.min(coinsToUse, product.price);
    const finalAmount = product.price - actualCoinsUsed;

    if (finalAmount <= 0) return res.json({ isFree: true });

    const paymentIntent = await stripe.paymentIntents.create({
      amount: finalAmount * 100, // in paise (for INR)
      currency: 'inr',
      metadata: { userId: req.userId, productId: productId, coinsUsed: actualCoinsUsed }
    });

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to initialize payment gateway" });
  }
});

// 3. Complete Checkout (no Stripe – for free / fully coin-paid orders)
router.post('/checkout', verifyToken, async (req, res) => {
  try {
    const { productId, coinsToUse, shippingAddress } = req.body;
    const user = await User.findById(req.userId);
    const product = await Product.findById(productId);

    if (!user || !product) return res.status(404).json({ error: "User or Product not found" });
    if (product.stock < 1) return res.status(400).json({ error: "Product out of stock" });

    const actualCoinsUsed = Math.min(coinsToUse, product.price);
    const finalAmount = product.price - actualCoinsUsed;

    // Deduct coins if used
    if (actualCoinsUsed > 0) {
      user.greenCoins -= actualCoinsUsed;
      await user.save();
    }

    // Decrease stock
    product.stock -= 1;
    await product.save();

    // Create order
    const order = new Order({
      user: req.userId,
      product: product._id,
      originalPrice: product.price,
      coinsUsed: actualCoinsUsed,
      finalAmountPaid: finalAmount,
      shippingAddress
    });

    await order.save();

    res.status(201).json({
      message: "Order placed successfully!",
      order,
      remainingCoins: user.greenCoins
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to save order" });
  }
});

// 4. Get User's Order History
router.get('/orders', verifyToken, async (req, res) => {
  try {
    const orders = await Order.find({ user: req.userId })
      .populate('product', 'name image category')
      .sort({ createdAt: -1 });
    res.json(orders);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch orders" });
  }
});

// 5. Seed Database – with updated, relevant image URLs (2026 verified)
router.post('/seed', async (req, res) => {
  try {
    const dummyProducts = [
      {
        name: "Eco-Friendly Water Bottle",
        price: 500,
        image: "https://www.adventurealan.com/wp-content/uploads/2025/01/5-100-Recycled-sustainable-water-bottles-min.jpg",
        description: "Reusable stainless steel bottle to eliminate plastic waste.",
        category: "Lifestyle",
        stock: 50
      },
      {
        name: "Bamboo Cutlery Set",
        price: 300,
        image: "https://masonjarlifestyle.com/cdn/shop/files/mason-jar-lifestyle-bamboo-utensil-set-roll-up-cotton-carrying-bag-fork-spoon-knife-chopsticks-straw-brush-flat.jpg?v=1695767078&width=1280",
        description: "Sustainable travel utensils for eating on the go.",
        category: "Dining",
        stock: 80
      },
      {
        name: "Solar Power Bank",
        price: 1500,
        image: "https://variety.com/wp-content/uploads/2025/04/blavor-charger-deal.jpg?w=731&h=476&crop=1",
        description: "Charge your devices anywhere using the power of the sun.",
        category: "Tech",
        stock: 30
      },
      {
        name: "Organic Cotton Tote",
        price: 250,
        image: "https://www.organiccottonmart.com/cdn/shop/products/Organic-Cotton-Canvas-Tote-Bags.jpg?v=1706779021",
        description: "Say no to plastic bags with this durable cotton tote.",
        category: "Lifestyle",
        stock: 100
      },
      {
        name: "Biodegradable Toothbrush",
        price: 150,
        image: "https://m.media-amazon.com/images/I/81CMBOybn6L.jpg",
        description: "Start your morning green with a 100% bamboo toothbrush.",
        category: "Hygiene",
        stock: 120
      }
    ];

    // Upsert (update if exists, insert if not) – forces fresh images & data
    for (const prod of dummyProducts) {
      await Product.findOneAndUpdate(
        { name: prod.name },
        prod,
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
    }

    res.json({ message: "Store seeded/updated with fresh, matching product images!" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Seeding failed" });
  }
});

module.exports = router;