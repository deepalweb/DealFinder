const express = require('express');
const router = express.Router();
router.use(require('express-rate-limit')({windowMs:60000,limit:20,standardHeaders:true,legacyHeaders:false}));
const multer = require('multer');
const imageStorage = require('../services/imageStorage');
const { uploadFolder, canDelete } = require('../utils/imagePolicy');
const { validateImage } = require('../utils/imageValidation');
const { authenticateJWT } = require('../middleware/auth');

const allowedImageExtensions = new Set(['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif']);

function hasAllowedImageExtension(filename = '') {
  const normalized = filename.toLowerCase();
  return Array.from(allowedImageExtensions).some((ext) => normalized.endsWith(ext));
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024, files:5, fields:4, fieldSize:1024, parts:10 }, // 20MB limit
  fileFilter: (req, file, cb) => {
    // The extension decides how the stored file is served, so it must be an image one.
    // Mime type is not checked: mobile clients often send application/octet-stream.
    if (hasAllowedImageExtension(file.originalname)) {
      cb(null, true);
    } else {
      cb(new Error('Only image files allowed'));
    }
  }
});

function runSingleUpload(req, res) {
  return new Promise((resolve, reject) => {
    upload.single('image')(req, res, (error) => {
      if (error) {
        return reject(error);
      }
      resolve();
    });
  });
}

function runMultipleUpload(req, res) {
  return new Promise((resolve, reject) => {
    upload.array('images', 5)(req, res, (error) => {
      if (error) {
        return reject(error);
      }
      resolve();
    });
  });
}

function handleUploadError(res, error) {
  console.error('❌ Upload middleware error:', error);

  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ message: 'Image file is too large. Please choose an image smaller than 20MB.' });
    }
    return res.status(400).json({ message: error.message });
  }

  return res.status(400).json({ message: error.message || 'Invalid image upload request' });
}

// Upload single image
router.post('/upload', authenticateJWT, async (req, res) => {
  try {
    await runSingleUpload(req, res);

    console.log('📤 Image upload request received');
    console.log('User:', req.user?.id, 'Role:', req.user?.role);
    console.log('File:', req.file ? `${req.file.originalname} (${req.file.size} bytes)` : 'No file');
    
    if (!req.file) {
      console.error('❌ No image file provided');
      return res.status(400).json({ message: 'No image file provided' });
    }

    if (!imageStorage.isConfigured()) {
      console.error('❌ Image storage not configured');
      return res.status(503).json({ message: 'Image upload service not configured' });
    }

    const files = req.files || (req.file ? [req.file] : []);
    for (const file of files) {
      if (!await validateImage(file)) return res.status(400).json({message:'The file is not a valid supported image or exceeds the pixel limit.'});
    }
    const folder = uploadFolder(req.user, req.body.folder);
    console.log('Uploading to folder:', folder);

    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const imageUrl = await imageStorage.uploadImage(req.file.buffer, req.file.originalname, folder, baseUrl);

    console.log('✅ Upload successful:', imageUrl);
    res.json({ imageUrl });
  } catch (error) {
    if (error instanceof multer.MulterError || error.message === 'Only image files allowed') {
      return handleUploadError(res, error);
    }
    console.error('❌ Image upload error:', error);
    res.status(500).json({ message: 'Failed to upload image' });
  }
});

// Upload multiple images
router.post('/upload-multiple', authenticateJWT, async (req, res) => {
  try {
    await runMultipleUpload(req, res);

    console.log('📤 Multiple images upload request received');
    console.log('User:', req.user?.id, 'Role:', req.user?.role);
    console.log('Files:', req.files ? `${req.files.length} files` : 'No files');
    
    if (!req.files || req.files.length === 0) {
      console.error('❌ No image files provided');
      return res.status(400).json({ message: 'No image files provided' });
    }

    if (!imageStorage.isConfigured()) {
      console.error('❌ Image storage not configured');
      return res.status(503).json({ message: 'Image upload service not configured' });
    }

    const files = req.files || (req.file ? [req.file] : []);
    for (const file of files) {
      if (!await validateImage(file)) return res.status(400).json({message:'The file is not a valid supported image or exceeds the pixel limit.'});
    }
    const folder = uploadFolder(req.user, req.body.folder);
    console.log('Uploading', req.files.length, 'files to folder:', folder);

    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const uploadPromises = req.files.map(file => {
      console.log('  -', file.originalname, `(${file.size} bytes)`);
      return imageStorage.uploadImage(file.buffer, file.originalname, folder, baseUrl);
    });

    const imageUrls = await Promise.all(uploadPromises);
    
    console.log('✅ All uploads successful');
    imageUrls.forEach((url, i) => console.log(`  ${i + 1}. ${url}`));

    res.json({ imageUrls });
  } catch (error) {
    if (error instanceof multer.MulterError || error.message === 'Only image files allowed') {
      return handleUploadError(res, error);
    }
    console.error('❌ Multiple image upload error:', error);
    res.status(500).json({ message: 'Failed to upload images' });
  }
});

// Delete image
router.delete('/delete', authenticateJWT, async (req, res) => {
  try {
    const { imageUrl } = req.body;

    if (!imageUrl) {
      return res.status(400).json({ message: 'Image URL required' });
    }

    if (!canDelete(req.user, imageUrl)) return res.status(403).json({ message: 'You may only delete images uploaded by your account. Legacy images must be managed by an administrator.' });
    await imageStorage.deleteImage(imageUrl);

    res.json({ message: 'Image deleted successfully' });
  } catch (error) {
    console.error('Image delete error:', error);
    res.status(500).json({ message: 'Failed to delete image' });
  }
});

module.exports = router;
