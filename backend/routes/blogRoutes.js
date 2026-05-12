const express = require("express");
const router = express.Router();
const Blog = require("../models/blog");
const User = require("../models/user");
const jwt = require("jsonwebtoken");

// 🔐 Verify Token 
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

// 📝 Create a new blog
router.post("/create", verifyToken, async (req, res) => {
  try {
    const { title, content, tags } = req.body;
    if (!title || !content) {
      return res.status(400).json({ message: "Title and content are required." });
    }

    const newBlog = new Blog({ title, content, tags, author: req.userId });
    await newBlog.save();
    res.status(201).json({ message: "Blog created successfully!", blog: newBlog });
  } catch (error) {
    res.status(500).json({ message: "Error creating blog", error: error.message });
  }
});

// 📜 Get all blogs
router.get("/", async (req, res) => {
  try {
    const blogs = await Blog.find().populate("author", "username").sort({ createdAt: -1 });
    res.status(200).json(blogs);
  } catch (error) {
    res.status(500).json({ message: "Error fetching blogs", error: error.message });
  }
});

// 🟢 FIXED: Get a single blog by ID (Now fetches comment usernames too!)
router.get("/:id", async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id)
      .populate("author", "username")
      .populate("comments.user", "username"); // THIS FIXES THE 'ANONYMOUS' BUG
      
    if (!blog) return res.status(404).json({ message: "Blog not found" });

    // Increment view count
    blog.views += 1;
    await blog.save();

    res.status(200).json(blog);
  } catch (error) {
    res.status(500).json({ message: "Error fetching blog", error: error.message });
  }
});

// ✏️ Update a blog
router.put("/:id", verifyToken, async (req, res) => {
  try {
    const { title, content, tags } = req.body;
    const blog = await Blog.findById(req.params.id);
    if (!blog) return res.status(404).json({ message: "Blog not found" });

    if (blog.author.toString() !== req.userId)
      return res.status(403).json({ message: "Unauthorized" });

    blog.title = title || blog.title;
    blog.content = content || blog.content;
    blog.tags = tags || blog.tags;
    await blog.save();

    res.status(200).json({ message: "Blog updated successfully", blog });
  } catch (error) {
    res.status(500).json({ message: "Error updating blog", error: error.message });
  }
});

// ❌ Delete a blog
router.delete("/:id", verifyToken, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) return res.status(404).json({ message: "Blog not found" });

    if (blog.author.toString() !== req.userId)
      return res.status(403).json({ message: "Unauthorized" });

    await blog.deleteOne();
    res.status(200).json({ message: "Blog deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Error deleting blog", error: error.message });
  }
});

// ❤️ Like a blog
router.put("/:id/like", verifyToken, async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) return res.status(404).json({ message: "Blog not found" });

    if (blog.likedBy.includes(req.userId)) {
      return res.status(400).json({ message: "Already liked" });
    }

    blog.likes += 1;
    blog.likedBy.push(req.userId);
    await blog.save();

    res.status(200).json({ message: "Blog liked!", likes: blog.likes, likedBy: blog.likedBy });
  } catch (error) {
    res.status(500).json({ message: "Error liking blog", error: error.message });
  }
});

// 💬 Add a comment to a blog
router.post("/:id/comment", verifyToken, async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) return res.status(400).json({ message: "Comment text required" });

    const blog = await Blog.findById(req.params.id);
    if (!blog) return res.status(404).json({ message: "Blog not found" });

    const newComment = {
      user: req.userId,
      text,
      timestamp: new Date()
    };

    blog.comments.push(newComment);
    await blog.save();

    // Populate user data before sending back
    const commentWithUser = await Blog.populate(blog, {
      path: "comments.user",
      select: "username"
    });

    res.status(201).json({ 
      message: "Comment added!",
      comment: commentWithUser.comments.slice(-1)[0]
    });
  } catch (error) {
    res.status(500).json({ message: "Error adding comment", error: error.message });
  }
});

module.exports = router;