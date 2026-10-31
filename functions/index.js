const functions = require('firebase-functions');
const crypto = require('crypto');

// Replace with your Cloudinary credentials
const CLOUDINARY_API_KEY = '241966296925978';
const CLOUDINARY_API_SECRET = 'mglahWuoBvP4DVF90QJ7S56jVS0';
const CLOUDINARY_CLOUD_NAME = 'civicease1'; // Replace with your Cloud Name

exports.getCloudinarySignature = functions.https.onCall((data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to get a signature.');
  }

  const userId = context.auth.uid;
  const timestamp = Math.floor(Date.now() / 1000); // Current timestamp in seconds
  const folder = `complaint_photos/${userId}`; // Organize uploads by userId

  // Parameters to sign (excluding the file itself)
  const paramsToSign = {
    timestamp: timestamp,
    folder: folder,
  };

  // Generate the signature
  const stringToSign = Object.keys(paramsToSign)
    .sort()
    .map(key => `${key}=${paramsToSign[key]}`)
    .join('&') + CLOUDINARY_API_SECRET;

  const signature = crypto.createHash('sha1')
    .update(stringToSign)
    .digest('hex');

  return {
    signature: signature,
    timestamp: timestamp,
    cloudName: CLOUDINARY_CLOUD_NAME,
    apiKey: CLOUDINARY_API_KEY,
    folder: folder,
  };
});