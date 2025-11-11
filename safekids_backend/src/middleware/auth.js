/**
 * Authentication Middleware
 * Verify JWT tokens and protect routes
 */

const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * Verify JWT token from Authorization header
 */
const auth = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Không tìm thấy token xác thực' 
      });
    }
    
    const token = authHeader.split(' ')[1];
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Find user from token
    const user = await User.findById(decoded.userId);
    
    if (!user) {
      return res.status(401).json({ error: 'Người dùng không tồn tại' });
    }
    
    if (!user.isActive) {
      return res.status(401).json({ error: 'Tài khoản đã bị vô hiệu hóa' });
    }
    
    // Attach user to request object
    req.user = user;
    req.userId = user._id;
    req.userRole = user.role;
    
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Token không hợp lệ' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token đã hết hạn. Vui lòng đăng nhập lại' });
    }
    return res.status(500).json({ error: 'Xác thực thất bại' });
  }
};

/**
 * Check if user is a parent
 */
const isParent = (req, res, next) => {
  if (req.userRole !== 'parent') {
    return res.status(403).json({ error: 'Chỉ phụ huynh mới có quyền truy cập' });
  }
  next();
};

/**
 * Check if user is a child
 */
const isChild = (req, res, next) => {
  if (req.userRole !== 'child') {
    return res.status(403).json({ error: 'Chỉ tài khoản con mới có quyền truy cập' });
  }
  next();
};

module.exports = {
  auth,
  isParent,
  isChild
};
