const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const EcoVideo = require("../models/EcoVideo");
const User = require("../models/user"); // Required to update the user's GreenCoins
const jwt = require("jsonwebtoken");
const upload = require("../config/multerCloudinary");

// Token verification middleware (Made bulletproof)
const getUserFromToken = (req) => {
  const authHeader = req.header("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded.userId || decoded.id || decoded._id; 
  } catch (err) {
    return null;
  }
};

const verifyToken = (req, res, next) => {
  req.userId = getUserFromToken(req);
  if (!req.userId) {
    return res.status(401).json({ success: false, message: "Invalid or no token" });
  }
  next();
};

// ────────────────────────────────────────────────
// UPLOAD VIDEO
// ────────────────────────────────────────────────
router.post(
  "/upload",
  verifyToken,
  upload.single("video"),
  async (req, res) => {
    try {
      console.log("╔══════════════════════════════════════╗");
      console.log("║ ECOLEARN VIDEO UPLOAD START         ║");
      console.log("╚══════════════════════════════════════╝");
      console.log("User ID:", req.userId);
      console.log("Form body:", req.body);

      if (!req.file) {
        console.log("→ No file received from multer");
        return res.status(400).json({
          success: false,
          message: "No video file received",
        });
      }

      const videoUrl = req.file.path;

      if (!videoUrl || typeof videoUrl !== "string" || !videoUrl.startsWith("https://res.cloudinary.com")) {
        console.error("Invalid or missing video URL from Cloudinary");
        return res.status(500).json({
          success: false,
          message: "Upload succeeded but no valid Cloudinary URL was generated",
        });
      }

      const { caption, category } = req.body;

      if (!caption?.trim()) {
        return res.status(400).json({ success: false, message: "Caption is required" });
      }

      if (!category?.trim()) {
        return res.status(400).json({ success: false, message: "Category is required" });
      }

      const newVideo = new EcoVideo({
        user: req.userId,
        videoUrl: videoUrl.trim(),
        caption: caption.trim(),
        category: category.trim(),
        status: "approved",
      });

      await newVideo.save();

      res.status(201).json({
        success: true,
        message: "Video uploaded successfully",
        video: {
          id: newVideo._id,
          videoUrl,
          caption: newVideo.caption,
          category: newVideo.category,
          status: newVideo.status,
        },
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({
        success: false,
        message: "Server error during video upload",
      });
    }
  }
);

// ────────────────────────────────────────────────
// DELETE VIDEO (Only owner or admin)
// ────────────────────────────────────────────────
router.delete("/video/:id", verifyToken, async (req, res) => {
  try {
    const video = await EcoVideo.findById(req.params.id);
    
    if (!video) {
      return res.status(404).json({ success: false, message: "Video not found" });
    }

    // Security Check: Only the uploader can delete their own video
    if (video.user.toString() !== req.userId.toString() && req.userRole !== "admin") {
      return res.status(403).json({ success: false, message: "Unauthorized to delete this video" });
    }

    await EcoVideo.findByIdAndDelete(req.params.id);
    
    res.json({ success: true, message: "Video deleted successfully" });
  } catch (err) {
    console.error("Delete video error:", err.message);
    res.status(500).json({ success: false, message: "Failed to delete video" });
  }
});

// ────────────────────────────────────────────────
// GET FEED
// ────────────────────────────────────────────────
router.get("/feed", async (req, res) => {
  try {
    const userId = getUserFromToken(req); 
    const videos = await EcoVideo.find({ status: "approved" })
      .populate("user", "username profilePic followers") 
      .populate({
        path: "comments.user",
        select: "username profilePic",
      })
      .sort({ createdAt: -1 })
      .limit(20);

    const personalizedVideos = videos.map((v) => {
      const videoObj = v.toObject();
      return {
        ...videoObj,
        likesCount: v.likes.length,
        userLiked: userId ? v.likes.some((id) => id.toString() === String(userId)) : false,
        isFollowing: userId ? v.user.followers.some((id) => id.toString() === String(userId)) : false,
        likes: undefined, 
      };
    });

    res.json(personalizedVideos);
  } catch (err) {
    console.error("Feed fetch error:", err.message);
    res.status(500).json({ success: false, message: "Failed to load feed" });
  }
});

// ────────────────────────────────────────────────
// VIEW COUNT & GREENCOIN REWARD SYSTEM
// ────────────────────────────────────────────────
router.post("/view/:id", async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: "Invalid video ID" });
    }

    // Increment the view count and return the updated video
    const video = await EcoVideo.findByIdAndUpdate(
      req.params.id,
      { $inc: { views: 1 } },
      { new: true }
    );

    if (!video) {
      return res.status(404).json({ success: false, message: "Video not found" });
    }

    // 🟢 Gamification: Reward 1 GreenCoin for every 50 views
    // If the new view count is exactly a multiple of 50 (e.g., 50, 100, 150)
    if (video.views > 0 && video.views % 50 === 0) {
      try {
        // Find the creator of the video and give them 1 coin
        await User.findByIdAndUpdate(
          video.user,
          { $inc: { greenCoins: 1 } }
        );
        console.log(`🎉 Awarded 1 GreenCoin to user ${video.user} for hitting ${video.views} views!`);
      } catch (rewardError) {
        console.error("Failed to award GreenCoin:", rewardError);
      }
    }

    res.json({
      success: true,
      message: "View counted",
      views: video.views,
    });
  } catch (err) {
    console.error("View increment error:", err.message);
    res.status(500).json({ success: false, message: "Failed to count view" });
  }
});

// ────────────────────────────────────────────────
// PENDING VIDEOS (ADMIN ONLY)
// ────────────────────────────────────────────────
router.get("/pending", verifyToken, async (req, res) => {
  try {
    if (req.userRole !== "admin") {
      return res.status(403).json({ success: false, message: "Admin access required" });
    }

    const videos = await EcoVideo.find({ status: "pending" })
      .populate("user", "username")
      .sort({ createdAt: -1 });

    res.json(videos);
  } catch (err) {
    res.status(500).json({ success: false, message: "Failed to fetch pending videos" });
  }
});

// ────────────────────────────────────────────────
// APPROVE VIDEO (ADMIN ONLY)
// ────────────────────────────────────────────────
router.post("/approve/:id", verifyToken, async (req, res) => {
  try {
    if (req.userRole !== "admin") {
      return res.status(403).json({ success: false, message: "Admin access required" });
    }

    const video = await EcoVideo.findByIdAndUpdate(
      req.params.id,
      { status: "approved" },
      { new: true }
    );

    if (!video) {
      return res.status(404).json({ success: false, message: "Video not found" });
    }

    res.json({ success: true, message: "Video approved", video });
  } catch (err) {
    res.status(500).json({ success: false, message: "Approval failed" });
  }
});

// ────────────────────────────────────────────────
// ADD COMMENT
// ────────────────────────────────────────────────
router.post("/comment/:videoId", verifyToken, async (req, res) => {
  try {
    const { text } = req.body;

    if (!text || typeof text !== "string" || text.trim() === "") {
      return res.status(400).json({ success: false, message: "Comment text is required" });
    }

    const video = await EcoVideo.findById(req.params.videoId);

    if (!video) {
      return res.status(404).json({ success: false, message: "Video not found" });
    }

    const newComment = {
      user: req.userId,
      text: text.trim(),
      createdAt: new Date(),
    };

    video.comments.push(newComment);
    await video.save();

    await video.populate({
      path: "comments.user",
      select: "username profilePic",
    });

    res.status(201).json({
      success: true,
      message: "Comment added successfully",
      comments: video.comments,
      totalComments: video.comments.length,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Failed to add comment" });
  }
});

// ────────────────────────────────────────────────
// TOGGLE LIKE
// ────────────────────────────────────────────────
router.post("/like/:videoId", verifyToken, async (req, res) => {
  try {
    const video = await EcoVideo.findById(req.params.videoId);

    if (!video) {
      return res.status(404).json({ success: false, message: "Video not found" });
    }

    const userId = req.userId;
    const alreadyLiked = video.likes.includes(userId);

    if (alreadyLiked) {
      video.likes = video.likes.filter((id) => id.toString() !== userId.toString());
    } else {
      video.likes.push(userId);
    }

    await video.save();

    res.status(200).json({
      success: true,
      liked: !alreadyLiked,
      totalLikes: video.likes.length,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Server error during like toggle" });
  }
});

// ────────────────────────────────────────────────
// 🔎 EXPLORE - CATEGORY + TRENDING
// ────────────────────────────────────────────────
router.get("/explore", async (req, res) => {
  try {
    const userId = getUserFromToken(req); 
    const { category, sort } = req.query;
    let filter = { status: "approved" };

    if (category && category !== "All") filter.category = category;

    let sortOption = { createdAt: -1 };
    if (sort === "trending") sortOption = { views: -1, likes: -1 };

    const videos = await EcoVideo.find(filter)
      // ✅ FIX: Populated user and comments so the frontend doesn't crash
      .populate("user", "username profilePic")
      .populate({
        path: "comments.user",
        select: "username profilePic",
      })
      .sort(sortOption)
      .limit(50);

    // ✅ FIX: Mapped data properly so likes and views sync up correctly
    const personalizedVideos = videos.map((v) => {
      const videoObj = v.toObject();
      return {
        ...videoObj,
        likesCount: v.likes.length,
        userLiked: userId ? v.likes.some((id) => id.toString() === String(userId)) : false,
        likes: undefined,
      };
    });

    res.status(200).json(personalizedVideos);
  } catch (err) {
    console.error("Explore Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ────────────────────────────────────────────────
// 📈 GET CREATOR PROFILE + VIDEOS
// ────────────────────────────────────────────────
router.get("/creator/:userId", async (req, res) => {
  try {
    const currentUserId = getUserFromToken(req); 

    // ✅ FIX: Added profilePic to select statement
    const creator = await User.findById(req.params.userId)
      .select("username profilePic followers following");

    if (!creator) {
      return res.status(404).json({ message: "User not found" });
    }

    const videos = await EcoVideo.find({
      user: req.params.userId,
      status: "approved"
    })
      // ✅ FIX: Populated user and comments so the frontend doesn't crash
      .populate("user", "username profilePic")
      .populate({
        path: "comments.user",
        select: "username profilePic",
      })
      .sort({ createdAt: -1 });

    const isFollowing = currentUserId 
      ? creator.followers.some(id => id.toString() === String(currentUserId)) 
      : false;

    // ✅ FIX: Mapped data properly so likes and views sync up correctly
    const personalizedVideos = videos.map((v) => {
      const videoObj = v.toObject();
      return {
        ...videoObj,
        likesCount: v.likes.length,
        userLiked: currentUserId ? v.likes.some((id) => id.toString() === String(currentUserId)) : false,
        likes: undefined,
      };
    });

    res.status(200).json({
      creator: {
        _id: creator._id,
        username: creator.username,
        profilePic: creator.profilePic, // ✅ Included profilePic
        followersCount: creator.followers.length,
        followingCount: creator.following.length,
        isFollowing 
      },
      videos: personalizedVideos // ✅ Send back the correctly mapped videos
    });

  } catch (err) {
    console.error("Creator Profile Error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ────────────────────────────────────────────────
// FOLLOW / UNFOLLOW USER
// ────────────────────────────────────────────────
router.post("/follow/:userId", verifyToken, async (req, res) => {
  try {
    const targetUser = await User.findById(req.params.userId);
    const currentUser = await User.findById(req.userId);

    if (!targetUser) return res.status(404).json({ success: false, message: "User not found" });
    if (targetUser._id.toString() === currentUser._id.toString()) {
      return res.status(400).json({ success: false, message: "Cannot follow yourself" });
    }

    const alreadyFollowing = currentUser.following.includes(targetUser._id);

    if (alreadyFollowing) {
      // Unfollow
      currentUser.following = currentUser.following.filter(
        (id) => id.toString() !== targetUser._id.toString()
      );
      targetUser.followers = targetUser.followers.filter(
        (id) => id.toString() !== currentUser._id.toString()
      );
    } else {
      // Follow
      currentUser.following.push(targetUser._id);
      targetUser.followers.push(currentUser._id);
    }

    await currentUser.save();
    await targetUser.save();

    res.status(200).json({
      success: true,
      following: !alreadyFollowing,
      followersCount: targetUser.followers.length,
    });
  } catch (err) {
    console.error("FOLLOW/UNFOLLOW ERROR", err.message);
    res.status(500).json({ success: false, message: "Server error during follow/unfollow" });
  }
});

module.exports = router;