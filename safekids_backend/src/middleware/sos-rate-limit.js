/**
 * SOS Rate Limit Middleware
 * Limits SOS trigger to 1 per 30 seconds per child (prevent abuse)
 */

// In-memory store: childId -> { timestamp, count }
const sosLimitMap = new Map();
const RATE_LIMIT_WINDOW = 30 * 1000; // 30 seconds
const MAX_SOS_PER_WINDOW = 1;

/**
 * Rate limit middleware for SOS triggers
 * Allows 1 SOS per 30 seconds per child
 */
const sosRateLimit = (req, res, next) => {
  const childId = req.userId;
  if (!childId) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  const now = Date.now();
  const limitData = sosLimitMap.get(childId);

  // Clean up old entries
  if (limitData && now - limitData.timestamp > RATE_LIMIT_WINDOW) {
    sosLimitMap.delete(childId);
    console.log(`[SOS RateLimit] Cleared limit for child ${childId}`);
  }

  const current = sosLimitMap.get(childId);

  if (current && current.count >= MAX_SOS_PER_WINDOW) {
    const secondsRemaining = Math.ceil((RATE_LIMIT_WINDOW - (now - current.timestamp)) / 1000);
    console.warn(`[SOS RateLimit] Rate limit exceeded for child ${childId}. Retry in ${secondsRemaining}s`);
    
    return res.status(429).json({ 
      error: `Quá nhiều SOS gửi liên tiếp. Vui lòng đợi ${secondsRemaining}s`,
      retryAfter: secondsRemaining 
    });
  }

  // Update rate limit
  if (current) {
    current.count += 1;
  } else {
    sosLimitMap.set(childId, {
      timestamp: now,
      count: 1
    });
  }

  console.log(`[SOS RateLimit] Child ${childId} - SOS count: ${sosLimitMap.get(childId).count}/${MAX_SOS_PER_WINDOW}`);
  
  next();
};

module.exports = sosRateLimit;
