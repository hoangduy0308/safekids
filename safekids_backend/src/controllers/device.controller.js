const User = require('../models/User');
const DeviceControl = require('../models/DeviceControl');

/**
 * @route   POST /api/device/lock
 * @desc    Send lock command to child device
 * @access  Private (parent only)
 */
exports.lockDevice = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.body;

    if (!childId) {
      return res.status(400).json({ error: 'Child ID is required' });
    }

    const parent = await User.findById(parentId);
    if (!parent || parent.role !== 'parent') {
      return res.status(403).json({ error: 'Only parents can lock devices' });
    }

    const child = await User.findById(childId);
    if (!child || child.role !== 'child') {
      return res.status(404).json({ error: 'Child not found' });
    }

    // Check if child is linked to this parent
    if (!parent.linkedChildren.includes(childId)) {
      return res.status(403).json({ error: 'Child is not linked to this parent' });
    }

    // Create or update device control record
    let deviceControl = await DeviceControl.findOne({ childId });
    
    if (!deviceControl) {
      deviceControl = new DeviceControl({
        childId,
        isLocked: true,
        lockedAt: new Date(),
        lockedBy: parentId,
      });
    } else {
      deviceControl.isLocked = true;
      deviceControl.lockedAt = new Date();
      deviceControl.lockedBy = parentId;
    }

    await deviceControl.save();

    res.json({
      success: true,
      message: `Device locked for ${child.name}`,
      data: {
        childId,
        childName: child.name,
        isLocked: true,
        lockedAt: deviceControl.lockedAt,
      }
    });

  } catch (error) {
    console.error('Lock device error:', error);
    res.status(500).json({ error: 'Cannot lock device' });
  }
};

/**
 * @route   POST /api/device/unlock
 * @desc    Send unlock command to child device
 * @access  Private (parent only)
 */
exports.unlockDevice = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.body;

    if (!childId) {
      return res.status(400).json({ error: 'Child ID is required' });
    }

    const parent = await User.findById(parentId);
    if (!parent || parent.role !== 'parent') {
      return res.status(403).json({ error: 'Only parents can unlock devices' });
    }

    const child = await User.findById(childId);
    if (!child || child.role !== 'child') {
      return res.status(404).json({ error: 'Child not found' });
    }

    // Check if child is linked to this parent
    if (!parent.linkedChildren.includes(childId)) {
      return res.status(403).json({ error: 'Child is not linked to this parent' });
    }

    // Update device control record
    let deviceControl = await DeviceControl.findOne({ childId });
    
    if (!deviceControl) {
      deviceControl = new DeviceControl({
        childId,
        isLocked: false,
        unlockedAt: new Date(),
        unlockedBy: parentId,
      });
    } else {
      deviceControl.isLocked = false;
      deviceControl.unlockedAt = new Date();
      deviceControl.unlockedBy = parentId;
    }

    await deviceControl.save();

    res.json({
      success: true,
      message: `Device unlocked for ${child.name}`,
      data: {
        childId,
        childName: child.name,
        isLocked: false,
        unlockedAt: deviceControl.unlockedAt,
      }
    });

  } catch (error) {
    console.error('Unlock device error:', error);
    res.status(500).json({ error: 'Cannot unlock device' });
  }
};
