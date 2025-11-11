/**
 * JWT Utility Functions
 * Generate and verify JWT tokens
 */

const jwt = require('jsonwebtoken');

/**
 * Generate JWT token for user
 * @param {string} userId - User ID
 * @param {string} role - User role (parent, child)
 * @returns {string} JWT token
 */
const generateToken = (userId, role = 'child') => {
  return jwt.sign(
    { userId, role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

/**
 * Verify JWT token
 * @param {string} token - JWT token to verify
 * @returns {object} Decoded token payload
 */
const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid token');
  }
};

module.exports = {
  generateToken,
  verifyToken
};
