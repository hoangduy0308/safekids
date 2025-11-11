/**
 * Device Routes - Các lệnh điều khiển thiết bị
 */

const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/device.controller');
const { auth } = require('../middleware/auth');

/**
 * @route   POST /api/device/lock
 * @desc    Lock child device
 * @access  Private (parent only)
 */
router.post('/lock', auth, deviceController.lockDevice);

/**
 * @route   POST /api/device/unlock
 * @desc    Unlock child device
 * @access  Private (parent only)
 */
router.post('/unlock', auth, deviceController.unlockDevice);

module.exports = router;
