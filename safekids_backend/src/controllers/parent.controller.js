const User = require('../models/User');

/**
 * @route   GET /api/parent/children
 * @desc    Get all linked children for parent
 * @access  Private
 */
exports.getMyChildren = async (req, res) => {
  try {
    const parentId = req.userId;
    
    const parent = await User.findById(parentId)
      .populate('linkedChildren', 'name fullName email role age avatar createdAt');
    
    if (!parent) {
      return res.status(404).json({ error: 'Parent not found' });
    }
    
    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Only parents can access this endpoint' });
    }
    
    // Return children data in the format expected by Flutter app
    const childrenData = (parent.linkedChildren || []).map(child => ({
      childId: child._id,
      _id: child._id,
      id: child._id,
      childName: child.name || child.fullName,
      name: child.name || child.fullName,
      fullName: child.fullName,
      email: child.email,
      role: child.role,
      age: child.age,
      avatar: child.avatar,
      createdAt: child.createdAt
    }));
    
    res.json({
      success: true,
      data: childrenData
    });
    
  } catch (error) {
    console.error('Get my children error:', error);
    res.status(500).json({ error: 'Cannot retrieve children' });
  }
};
