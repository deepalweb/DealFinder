const express = require('express');
const router = express.Router();
const multer = require('multer');
const azureBlobService = require('../services/azureBlobService');
const { authenticateJWT } = require('../middleware/auth');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files allowed'));
    }
  }
});

// Upload single image
router.post('/upload', authenticateJWT, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided' });
    }

    if (!azureBlobService.isConfigured()) {
      return res.status(503).json({ message: 'Image upload service not configured' });
    }

    const folder = req.body.folder || 'images';
    const imageUrl = await azureBlobService.uploadImage(req.file.buffer, req.file.originalname, folder);

    res.json({ imageUrl });
  } catch (error) {
    console.error('Image upload error:', error);
    res.status(500).json({ message: 'Failed to upload image', error: error.message });
  }
});

// Upload multiple images
router.post('/upload-multiple', authenticateJWT, upload.array('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'No image files provided' });
    }

    if (!azureBlobService.isConfigured()) {
      return res.status(503).json({ message: 'Image upload service not configured' });
    }

    const folder = req.body.folder || 'images';
    const uploadPromises = req.files.map(file => 
      azureBlobService.uploadImage(file.buffer, file.originalname, folder)
    );

    const imageUrls = await Promise.all(uploadPromises);

    res.json({ imageUrls });
  } catch (error) {
    console.error('Multiple image upload error:', error);
    res.status(500).json({ message: 'Failed to upload images', error: error.message });
  }
});

// Delete image
router.delete('/delete', authenticateJWT, async (req, res) => {
  try {
    const { imageUrl } = req.body;

    if (!imageUrl) {
      return res.status(400).json({ message: 'Image URL required' });
    }

    await azureBlobService.deleteImage(imageUrl);

    res.json({ message: 'Image deleted successfully' });
  } catch (error) {
    console.error('Image delete error:', error);
    res.status(500).json({ message: 'Failed to delete image', error: error.message });
  }
});

module.exports = router;
