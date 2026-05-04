const express = require('express');
const router = express.Router();
const multer = require('multer');
const azureBlobService = require('../services/azureBlobService');
const { authenticateJWT } = require('../middleware/auth');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 }, // 20MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
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

    if (!azureBlobService.isConfigured()) {
      console.error('❌ Azure Blob Storage not configured');
      return res.status(503).json({ message: 'Image upload service not configured' });
    }

    const folder = req.body.folder || 'images';
    console.log('Uploading to folder:', folder);
    
    const imageUrl = await azureBlobService.uploadImage(req.file.buffer, req.file.originalname, folder);
    
    console.log('✅ Upload successful:', imageUrl);
    res.json({ imageUrl });
  } catch (error) {
    if (error instanceof multer.MulterError || error.message === 'Only image files allowed') {
      return handleUploadError(res, error);
    }
    console.error('❌ Image upload error:', error);
    res.status(500).json({ message: 'Failed to upload image', error: error.message });
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

    if (!azureBlobService.isConfigured()) {
      console.error('❌ Azure Blob Storage not configured');
      return res.status(503).json({ message: 'Image upload service not configured' });
    }

    const folder = req.body.folder || 'images';
    console.log('Uploading', req.files.length, 'files to folder:', folder);
    
    const uploadPromises = req.files.map(file => {
      console.log('  -', file.originalname, `(${file.size} bytes)`);
      return azureBlobService.uploadImage(file.buffer, file.originalname, folder);
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
