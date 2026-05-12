const multer = require("multer");
const { CloudinaryStorage } = require("multer-storage-cloudinary");
const cloudinary = require("./cloudinary");

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: (req, file) => {
    return {
      folder: "ecolearn_videos",
      resource_type: "video",
      allowed_formats: ["mp4", "mov", "webm", "avi"],
      // Optional: add quality optimization
      // transformation: [{ quality: "auto:good" }, { fetch_format: "auto" }],
    };
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 150 * 1024 * 1024, // 150 MB
  },
  fileFilter: (req, file, cb) => {
    const allowed = ["video/mp4", "video/quicktime", "video/webm", "video/x-msvideo"];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("Only video files are allowed (.mp4, .mov, .webm, .avi)"), false);
    }
  },
});

module.exports = upload;