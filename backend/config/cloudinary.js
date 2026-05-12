const cloudinary = require("cloudinary").v2;

console.log("[CLOUDINARY] Initializing configuration...");

if (process.env.CLOUDINARY_URL) {
  console.log("[CLOUDINARY] → Using CLOUDINARY_URL from env");
  cloudinary.config({
    cloudinary_url: process.env.CLOUDINARY_URL,
    secure: true,
  });
} else {
  console.log("[CLOUDINARY] → Using separate variables (cloud_name, api_key, api_secret)");
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
  });
}

// Print resolved configuration (very helpful for debugging)
console.log("[CLOUDINARY] Final effective config:", {
  cloud_name: cloudinary.config().cloud_name || "NOT SET",
  api_key: cloudinary.config().api_key ? "present" : "MISSING",
  api_secret: cloudinary.config().api_secret ? "present" : "MISSING",
});

module.exports = cloudinary;