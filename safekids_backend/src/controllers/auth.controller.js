/**
 * Authentication Controller
 * Handles user registration, login, and linking
 */

const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const User = require("../models/User");
const emailService = require("../services/email.service");
const smsService = require("../services/sms.service");

/**
 * Generate JWT token
 */
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "7d",
  });
};

/**
 * @route   POST /api/auth/register
 * @desc    Register new user (parent or child)
 * @access  Public
 */
exports.register = async (req, res) => {
  try {
    const { fullName, email, password, phone, role, age } = req.body;

    // Validation
    if (!fullName || !email || !password || !phone || !role) {
      return res.status(400).json({
        error:
          "Vui lòng cung cấp đầy đủ thông tin: họ tên, email, mật khẩu, số điện thoại, vai trò",
      });
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: "Email không hợp lệ" });
    }

    // Password validation - minimum 6 characters
    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: "Mật khẩu phải có ít nhất 6 ký tự" });
    }

    // Role validation
    if (!["parent", "child"].includes(role)) {
      return res.status(400).json({ message: "Vai trò không hợp lệ" });
    }

    // Child-specific validation
    if (role === "child") {
      if (!age) {
        return res
          .status(400)
          .json({ message: "Tài khoản con cần cung cấp độ tuổi" });
      }
      if (age < 6 || age > 17) {
        return res
          .status(400)
          .json({ message: "Độ tuổi cho tài khoản con phải từ 6-17 tuổi" });
      }
    }
    const phoneRegex = /^[0-9]{10,15}$/;
    if (!phoneRegex.test(phone)) {
      return res.status(400).json({ message: "Số điện thoại không hợp lệ" });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: "Email đã được đăng ký" });
    }

    // Generate username from email (remove domain part)
    let username = email.split("@")[0].toLowerCase();

    // Check if username already exists
    let existingUsername = await User.findOne({ username });
    let counter = 1;
    while (existingUsername && counter < 100) {
      username = `${email.split("@")[0].toLowerCase()}${counter}`;
      existingUsername = await User.findOne({ username });
      counter++;
    }

    // Create user
    const user = new User({
      fullName,
      name: fullName, // Sync name to fullName for compatibility
      email,
      username,
      password,
      phone,
      role,
      ...(role === "child" && { age }),
      isEmailVerified: false,
    });

    await user.save();

    // Generate email verification token
    const verificationToken = crypto.randomBytes(32).toString("hex");
    const hashedToken = crypto
      .createHash("sha256")
      .update(verificationToken)
      .digest("hex");

    user.emailVerificationToken = hashedToken;
    user.emailVerificationExpires = Date.now() + 86400000;
    await user.save();

    // Send verification email
    try {
      if (emailService.isConfigured) {
        await emailService.sendVerificationEmail(
          user.email,
          verificationToken,
          user.fullName || user.name
        );
        console.log(`✅ Verification email sent to ${user.email}`);
      } else {
        console.warn(
          "⚠️ Email service not configured, skipping verification email"
        );
      }
    } catch (emailError) {
      console.error("Failed to send verification email:", emailError.message);
    }

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      message:
        "Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.",
      token,
      user: user.toPublicJSON(),
      emailVerificationRequired: true,
    });
  } catch (error) {
    console.error("Register error:", error);
    res
      .status(500)
      .json({ message: error.message || "Đăng ký thất bại. Vui lòng thử lại" });
  }
};

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res
        .status(400)
        .json({ message: "Vui lòng nhập email và mật khẩu" });
    }

    // Find user (include password field)
    const user = await User.findOne({ email }).select("+password");
    if (!user) {
      return res
        .status(401)
        .json({ message: "Email hoặc mật khẩu không đúng" });
    }

    // Check if account is active
    if (!user.isActive) {
      return res.status(401).json({ message: "Tài khoản đã bị vô hiệu hóa" });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res
        .status(401)
        .json({ message: "Email hoặc mật khẩu không đúng" });
    }

    // Check email verification
    if (!user.isEmailVerified) {
      return res.status(403).json({
        message:
          "Vui lòng xác thực email trước khi đăng nhập. Kiểm tra hộp thư của bạn.",
        emailVerificationRequired: true,
        email: user.email,
      });
    }

    // Generate token
    const token = generateToken(user._id);

    // Update FCM token if provided
    if (req.body.fcmToken) {
      user.fcmToken = req.body.fcmToken;
      await user.save();
    }

    res.json({
      message: "Đăng nhập thành công",
      token,
      user: user.toPublicJSON(),
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Đăng nhập thất bại. Vui lòng thử lại" });
  }
};

/**
 * @route   GET /api/auth/me
 * @desc    Get current user profile with linked accounts
 * @access  Private
 */
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.userId)
      .populate("linkedChildren", "name fullName email role age avatar")
      .populate("linkedParents", "name fullName email role age avatar")
      .select("-password");

    if (!user) {
      return res.status(404).json({
        message: "Không tìm thấy người dùng",
      });
    }

    // Return user with populated linked accounts
    const userData = user.toObject();

    // Combine linkedChildren and linkedParents into linkedUsers for backward compatibility
    const linkedUsers = [
      ...(userData.linkedChildren || []),
      ...(userData.linkedParents || []),
    ];

    res.json({
      user: {
        id: userData._id,
        _id: userData._id,
        name: userData.name || userData.fullName,
        fullName: userData.fullName,
        email: userData.email,
        phone: userData.phone,
        role: userData.role,
        age: userData.age,
        avatar: userData.avatar,
        linkedUsers: linkedUsers, // Combined list for backward compatibility
        linkedUsersData: linkedUsers, // Populated objects for Flutter app
        linkedChildren: userData.linkedChildren || [],
        linkedParents: userData.linkedParents || [],
        createdAt: userData.createdAt,
      },
    });
  } catch (error) {
    console.error("Get me error:", error);
    res.status(500).json({
      message: "Không thể tải thông tin người dùng",
    });
  }
};

/**
 * @route   POST /api/auth/link
 * @desc    Link parent and child accounts
 * @access  Private (Parent only)
 */
exports.linkAccounts = async (req, res) => {
  try {
    const { targetUserId, childEmail } = req.body;

    // Get current user
    const currentUser = await User.findById(req.userId);

    // Verify requester is parent
    if (currentUser.role !== "parent") {
      return res.status(403).json({
        message: "Chỉ phụ huynh mới có thể liên kết tài khoản trẻ em",
      });
    }

    let targetUser;

    // Support both email and userId for linking
    if (childEmail) {
      targetUser = await User.findOne({
        email: childEmail.toLowerCase().trim(),
      });

      if (!targetUser) {
        return res.status(404).json({
          message: "Không tìm thấy tài khoản trẻ em với email này",
        });
      }
    } else if (targetUserId) {
      targetUser = await User.findById(targetUserId);

      if (!targetUser) {
        return res.status(404).json({
          message: "Không tìm thấy tài khoản người dùng",
        });
      }
    } else {
      return res.status(400).json({
        message: "Vui lòng cung cấp email hoặc ID của trẻ em",
      });
    }

    // Verify target is a child account
    if (targetUser.role !== "child") {
      return res.status(400).json({
        message: "Email này là tài khoản phụ huynh, không phải trẻ em",
      });
    }

    // Check if already linked
    if (
      currentUser.linkedUsers.some(
        (id) => id.toString() === targetUser._id.toString()
      )
    ) {
      return res.status(400).json({
        message: "Trẻ em này đã được liên kết với tài khoản của bạn",
      });
    }

    // Add to linked users (bidirectional)
    currentUser.linkedUsers.push(targetUser._id);
    targetUser.linkedUsers.push(currentUser._id);

    // Also add to specific relationship arrays (for getMe)
    // Parent adds child to linkedChildren
    if (
      currentUser.role === "parent" &&
      !currentUser.linkedChildren.includes(targetUser._id)
    ) {
      currentUser.linkedChildren.push(targetUser._id);
    }
    // Child adds parent to linkedParents
    if (
      targetUser.role === "child" &&
      !targetUser.linkedParents.includes(currentUser._id)
    ) {
      targetUser.linkedParents.push(currentUser._id);
    }

    console.log(
      `✅ Linked: ${currentUser.name} (parent) → ${targetUser.name} (child)`
    );
    console.log(
      `   Parent linkedChildren: ${currentUser.linkedChildren.length}`
    );
    console.log(`   Child linkedParents: ${targetUser.linkedParents.length}`);

    await currentUser.save();
    await targetUser.save();

    res.json({
      message: `Đã liên kết thành công với ${targetUser.name}`,
      linkedUser: targetUser.toPublicJSON(),
    });
  } catch (error) {
    console.error("Link accounts error:", error);
    res.status(500).json({
      message: "Liên kết tài khoản thất bại. Vui lòng thử lại",
    });
  }
};

/**
 * @route   GET /api/auth/profile
 * @desc    Get user profile (Task 2.5.1)
 * @access  Private
 */
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.userId)
      .populate("linkedChildren", "name email role")
      .populate("linkedParents", "name email role");

    if (!user) {
      return res.status(404).json({ error: "Người dùng không tồn tại" });
    }

    res.json({
      success: true,
      data: {
        user: user.toPublicJSON(),
      },
    });
  } catch (error) {
    console.error("Get profile error:", error);
    res.status(500).json({ error: "Không thể lấy thông tin" });
  }
};

/**
 * @route   PUT /api/auth/profile
 * @desc    Update user profile (fullName, phone only)
 * @access  Private
 */
exports.updateProfile = async (req, res) => {
  try {
    const { fullName, phone } = req.body;

    // Only allow updating specific fields
    const updates = {};
    if (fullName !== undefined) {
      if (!fullName || fullName.trim() === "") {
        return res.status(400).json({ error: "Họ tên không được để trống" });
      }
      updates.fullName = fullName.trim();
      updates.name = fullName.trim(); // Keep name field in sync
    }

    if (phone !== undefined) {
      if (phone && phone.trim() !== "") {
        // Basic phone validation
        const phoneRegex = /^[0-9]{10,15}$/;
        if (!phoneRegex.test(phone.trim())) {
          return res.status(400).json({ error: "Số điện thoại không hợp lệ" });
        }
        updates.phone = phone.trim();
      } else {
        updates.phone = phone; // Allow empty string to clear phone
      }
    }

    if (Object.keys(updates).length === 0) {
      return res
        .status(400)
        .json({ error: "Không có thông tin nào để cập nhật" });
    }

    // Update user
    const user = await User.findByIdAndUpdate(req.userId, updates, {
      new: true,
      runValidators: true,
    })
      .populate("linkedChildren", "name email role")
      .populate("linkedParents", "name email role");

    if (!user) {
      return res.status(404).json({ error: "Người dùng không tồn tại" });
    }

    res.json({
      message: "Đã cập nhật thông tin",
      user: user.toPublicJSON(),
    });
  } catch (error) {
    console.error("Update profile error:", error);
    res.status(500).json({ error: "Không thể cập nhật. Vui lòng thử lại" });
  }
};

/**
 * @route   POST /api/auth/update-fcm-token
 * @desc    Update FCM token for push notifications
 * @access  Private
 */
exports.updateFCMToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ error: "FCM token is required" });
    }

    const user = await User.findById(req.userId);
    user.fcmToken = fcmToken;
    await user.save();

    res.json({ message: "FCM token updated successfully" });
  } catch (error) {
    console.error("Update FCM token error:", error);
    res.status(500).json({ error: "Failed to update FCM token" });
  }
};

/**
 * @route   PUT /api/auth/location-settings
 * @desc    Update child's location sharing settings (Task 2.5)
 * @access  Private (Child only)
 */
exports.updateLocationSettings = async (req, res) => {
  try {
    const userId = req.userId;
    const { sharingEnabled, trackingInterval, pausedUntil } = req.body;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Only child users can update location settings
    if (user.role !== "child") {
      return res
        .status(403)
        .json({ error: "Only child users can update location settings" });
    }

    const oldSharingEnabled = user.locationSettings?.sharingEnabled ?? true;

    console.log(
      `🔍 Current sharing status: ${oldSharingEnabled}, Requested: ${sharingEnabled}`
    );

    // Task 2.5.2: Validate tracking interval
    if (trackingInterval) {
      const validIntervals = ["continuous", "normal", "battery-saver"];
      if (!validIntervals.includes(trackingInterval)) {
        return res.status(422).json({
          error: "Invalid tracking interval",
          validOptions: validIntervals,
        });
      }
    }

    // Update settings
    if (sharingEnabled !== undefined) {
      user.locationSettings.sharingEnabled = sharingEnabled;
    }
    if (trackingInterval) {
      user.locationSettings.trackingInterval = trackingInterval;
    }
    if (pausedUntil !== undefined) {
      user.locationSettings.pausedUntil = pausedUntil
        ? new Date(pausedUntil)
        : null;
    }

    await user.save();
    console.log(`✅ Location settings updated for ${user.name}`);

    // Task 2.5.3: Notify parents if sharing status changed
    if (sharingEnabled !== undefined && oldSharingEnabled !== sharingEnabled) {
      try {
        const parents = await User.find({ _id: { $in: user.linkedParents } });
        const notificationService = req.app.get("notificationService");

        const message = user.locationSettings.sharingEnabled
          ? `${user.name} đã bật lại chia sẻ vị trí`
          : `${user.name} đã tắt chia sẻ vị trí`;

        console.log(`📢 Found ${parents.length} parents`);
        console.log(`📢 NotificationService exists: ${!!notificationService}`);

        if (!notificationService) {
          console.error("❌ NotificationService not initialized on app");
        }

        if (parents.length === 0) {
          console.warn("⚠️ No linked parents found");
        }

        let notifiedCount = 0;
        parents.forEach((parent, idx) => {
          console.log(
            `Parent ${idx}: fcmToken=${
              parent.fcmToken ? "EXISTS" : "MISSING"
            }, name=${parent.name}`
          );

          if (parent.fcmToken && notificationService) {
            notificationService.sendNotification(
              parent.fcmToken,
              "Cập nhật vị trí",
              message,
              {
                childId: userId.toString(),
                childName: user.name,
                sharingEnabled: user.locationSettings.sharingEnabled.toString(),
              }
            );
            notifiedCount++;
            console.log(`✅ Notification sent to parent: ${parent.name}`);
          } else {
            console.warn(
              `⚠️ Skipped parent ${
                parent.name
              }: fcmToken=${!!parent.fcmToken}, notificationService=${!!notificationService}`
            );
          }
        });

        console.log(
          `📢 Successfully notified ${notifiedCount}/${parents.length} parents: ${message}`
        );
      } catch (notifyError) {
        console.error("❌ Error notifying parents:", notifyError);
        // Don't fail the request if notification fails
      }
    }

    res.json({
      success: true,
      message: "Location settings updated successfully",
      data: {
        locationSettings: user.locationSettings,
      },
    });
  } catch (error) {
    console.error("Update location settings error:", error);
    res.status(500).json({ error: "Failed to update location settings" });
  }
};

/**
 * @route   POST /api/auth/forgot-password
 * @desc    Send password reset OTP via email or SMS
 * @access  Public
 */
exports.forgotPassword = async (req, res) => {
  try {
    const { email, phone, method } = req.body;

    // Validate method
    if (!method || !["email", "sms"].includes(method)) {
      return res
        .status(400)
        .json({ message: 'Phương thức không hợp lệ. Chọn "email" hoặc "sms"' });
    }

    // Validate input based on method
    if (method === "email" && !email) {
      return res.status(400).json({ message: "Vui lòng nhập email" });
    }

    if (method === "sms" && !phone) {
      return res.status(400).json({ message: "Vui lòng nhập số điện thoại" });
    }

    // Find user based on method
    let user;
    if (method === "email") {
      user = await User.findOne({ email: email.toLowerCase().trim() });
      if (!user) {
        return res
          .status(404)
          .json({ message: "Không tìm thấy tài khoản với email này" });
      }
    } else {
      user = await User.findOne({ phone: phone.trim() });
      if (!user) {
        return res
          .status(404)
          .json({ message: "Không tìm thấy tài khoản với số điện thoại này" });
      }
    }

    // Send OTP based on method
    try {
      if (method === "email") {
        // Check if email service is configured
        if (!emailService.isConfigured) {
          return res.status(503).json({
            message:
              "Dịch vụ email chưa được cấu hình. Vui lòng thử phương thức SMS hoặc liên hệ admin.",
          });
        }

        // Generate 6-digit OTP for email
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Hash OTP before saving
        const hashedOTP = crypto.createHash("sha256").update(otp).digest("hex");

        // Save OTP to database (only for email method)
        user.resetPasswordOTP = hashedOTP;
        user.resetPasswordExpires = Date.now() + 900000; // 15 minutes
        user.resetPasswordMethod = method;
        await user.save();

        await emailService.sendPasswordResetOTP(
          user.email,
          otp,
          user.fullName || user.name
        );

        res.json({
          success: true,
          message: "Mã OTP đã được gửi đến email của bạn",
          method: "email",
          expiresIn: "15 phút",
        });
      } else if (method === "sms") {
        // Check if SMS service is configured
        if (!smsService.isConfigured) {
          return res.status(503).json({
            message:
              "Dịch vụ SMS chưa được cấu hình. Vui lòng thử phương thức email hoặc liên hệ admin.",
          });
        }

        // Use Twilio Verify API - no need to generate or save OTP
        // Twilio handles OTP generation, storage, and expiry
        const phoneToSend = phone || user.phone;
        if (!phoneToSend) {
          return res.status(400).json({
            message: "Không tìm thấy số điện thoại",
          });
        }

        await smsService.sendVerificationCode(phoneToSend);

        // Save method for verification later
        user.resetPasswordMethod = method;
        await user.save();

        res.json({
          success: true,
          message: "Mã OTP đã được gửi đến số điện thoại của bạn",
          method: "sms",
          expiresIn: "10 phút",
          // Mask phone number for security
          phone: phoneToSend.replace(/(\d{2})\d{4}(\d{4})/, "$1****$2"),
        });
      }
    } catch (sendError) {
      // Rollback: clear data if sending failed
      if (method === "email") {
        user.resetPasswordOTP = undefined;
        user.resetPasswordExpires = undefined;
      }
      user.resetPasswordMethod = undefined;
      await user.save();

      console.error(`Failed to send OTP via ${method}:`, sendError.message);
      throw sendError;
    }
  } catch (error) {
    console.error("Forgot password error:", error);
    res.status(500).json({
      message: error.message || "Không thể xử lý yêu cầu. Vui lòng thử lại",
    });
  }
};

/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset password with OTP
 * @access  Public
 */
exports.resetPassword = async (req, res) => {
  try {
    const { email, phone, otp, newPassword } = req.body;

    // Validate input
    if (!otp || !newPassword) {
      return res
        .status(400)
        .json({ message: "Vui lòng cung cấp mã OTP và mật khẩu mới" });
    }

    if (!email && !phone) {
      return res
        .status(400)
        .json({ message: "Vui lòng cung cấp email hoặc số điện thoại" });
    }

    if (newPassword.length < 6) {
      return res
        .status(400)
        .json({ message: "Mật khẩu phải có ít nhất 6 ký tự" });
    }

    if (otp.length !== 6 || !/^\d{6}$/.test(otp)) {
      return res.status(400).json({ message: "Mã OTP phải là 6 chữ số" });
    }

    // Find user based on email or phone
    let user;
    if (email) {
      user = await User.findOne({
        email: email.toLowerCase().trim(),
      }).select("+password +resetPasswordOTP");
    } else {
      user = await User.findOne({
        phone: phone.trim(),
      }).select("+password +resetPasswordOTP");
    }

    if (!user) {
      return res.status(400).json({ message: "Không tìm thấy tài khoản" });
    }

    // Check which method was used
    const method = user.resetPasswordMethod;

    if (!method) {
      return res.status(400).json({
        message:
          "Không tìm thấy yêu cầu đặt lại mật khẩu. Vui lòng yêu cầu lại mã OTP.",
      });
    }

    // Verify OTP based on method
    let isValidOTP = false;

    if (method === "email") {
      // Manual verification for email OTP
      if (!user.resetPasswordOTP || !user.resetPasswordExpires) {
        return res
          .status(400)
          .json({ message: "Mã OTP đã hết hạn. Vui lòng yêu cầu lại." });
      }

      if (user.resetPasswordExpires < Date.now()) {
        return res.status(400).json({ message: "Mã OTP đã hết hạn" });
      }

      // Hash the OTP to compare with stored hash
      const hashedOTP = crypto.createHash("sha256").update(otp).digest("hex");

      if (user.resetPasswordOTP !== hashedOTP) {
        return res.status(400).json({ message: "Mã OTP không chính xác" });
      }

      isValidOTP = true;
    } else if (method === "sms") {
      // Twilio Verify API verification for SMS
      const phoneToVerify = phone || user.phone;
      if (!phoneToVerify) {
        return res.status(400).json({ message: "Số điện thoại không hợp lệ" });
      }

      try {
        const verification = await smsService.verifyCode(phoneToVerify, otp);

        if (!verification.success) {
          return res
            .status(400)
            .json({ message: "Mã OTP không chính xác hoặc đã hết hạn" });
        }

        isValidOTP = true;
      } catch (verifyError) {
        console.error("SMS verification error:", verifyError.message);
        return res.status(400).json({ message: verifyError.message });
      }
    }

    if (!isValidOTP) {
      return res.status(400).json({ message: "Xác thực OTP thất bại" });
    }

    // Update password
    user.password = newPassword;
    user.resetPasswordOTP = undefined;
    user.resetPasswordExpires = undefined;
    user.resetPasswordMethod = undefined;

    await user.save();

    console.log(
      `✅ Password reset successful for user: ${user.email} (method: ${method})`
    );

    res.json({
      success: true,
      message: "Đặt lại mật khẩu thành công",
    });
  } catch (error) {
    console.error("Reset password error:", error);
    res
      .status(500)
      .json({ message: "Không thể đặt lại mật khẩu. Vui lòng thử lại" });
  }
};

/**
 * @route   GET /api/auth/verify-email
 * @desc    Verify email with token
 * @access  Public
 */
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res
        .status(400)
        .send(_renderErrorPage("Token xác thực không hợp lệ"));
    }

    // Hash token to compare with stored hash
    const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

    // Find user with valid token
    const user = await User.findOne({
      emailVerificationToken: hashedToken,
      emailVerificationExpires: { $gt: Date.now() },
    }).select("+emailVerificationToken");

    if (!user) {
      return res
        .status(400)
        .send(_renderErrorPage("Token xác thực không hợp lệ hoặc đã hết hạn"));
    }

    // Verify email
    user.isEmailVerified = true;
    user.emailVerificationToken = undefined;
    user.emailVerificationExpires = undefined;

    await user.save();

    console.log(`✅ Email verified successfully for user: ${user.email}`);

    // Return HTML success page
    res.send(_renderSuccessPage(user.name || user.email));
  } catch (error) {
    console.error("Verify email error:", error);
    res
      .status(500)
      .send(_renderErrorPage("Không thể xác thực email. Vui lòng thử lại"));
  }
};

/**
 * Render success HTML page
 */
function _renderSuccessPage(userName) {
  return `
    <!DOCTYPE html>
    <html lang="vi">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Xác thực thành công - SafeKids</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
        }
        .container {
          background: white;
          border-radius: 20px;
          padding: 40px;
          max-width: 500px;
          width: 100%;
          box-shadow: 0 20px 60px rgba(0,0,0,0.3);
          text-align: center;
          animation: slideUp 0.5s ease-out;
        }
        @keyframes slideUp {
          from { opacity: 0; transform: translateY(30px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .icon {
          width: 80px;
          height: 80px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 24px;
          animation: scaleIn 0.6s ease-out 0.2s both;
        }
        @keyframes scaleIn {
          from { transform: scale(0); }
          to { transform: scale(1); }
        }
        .checkmark {
          color: white;
          font-size: 48px;
          font-weight: bold;
        }
        h1 {
          color: #1a202c;
          font-size: 28px;
          margin-bottom: 12px;
          font-weight: 700;
        }
        p {
          color: #4a5568;
          font-size: 16px;
          line-height: 1.6;
          margin-bottom: 32px;
        }
        .username {
          color: #667eea;
          font-weight: 600;
        }
        .button {
          display: inline-block;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          text-decoration: none;
          padding: 14px 32px;
          border-radius: 10px;
          font-weight: 600;
          font-size: 16px;
          transition: transform 0.2s, box-shadow 0.2s;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        .button:hover {
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
        }
        .footer {
          margin-top: 24px;
          padding-top: 24px;
          border-top: 1px solid #e2e8f0;
          color: #718096;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">
          <div class="checkmark">✓</div>
        </div>
        <h1>Xác thực thành công!</h1>
        <p>
          Xin chào <span class="username">${userName}</span>,<br>
          Email của bạn đã được xác thực thành công.<br>
          Bạn có thể đóng trang này và đăng nhập vào ứng dụng SafeKids.
        </p>
        <a href="#" onclick="window.close(); return false;" class="button">
          Đóng trang này
        </a>
        <div class="footer">
          © ${new Date().getFullYear()} SafeKids. All rights reserved.
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * Render error HTML page
 */
function _renderErrorPage(errorMessage) {
  return `
    <!DOCTYPE html>
    <html lang="vi">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Lỗi xác thực - SafeKids</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          background: linear-gradient(135deg, #f56565 0%, #c53030 100%);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
        }
        .container {
          background: white;
          border-radius: 20px;
          padding: 40px;
          max-width: 500px;
          width: 100%;
          box-shadow: 0 20px 60px rgba(0,0,0,0.3);
          text-align: center;
          animation: slideUp 0.5s ease-out;
        }
        @keyframes slideUp {
          from { opacity: 0; transform: translateY(30px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .icon {
          width: 80px;
          height: 80px;
          background: linear-gradient(135deg, #f56565 0%, #c53030 100%);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 24px;
        }
        .cross {
          color: white;
          font-size: 48px;
          font-weight: bold;
        }
        h1 {
          color: #1a202c;
          font-size: 28px;
          margin-bottom: 12px;
          font-weight: 700;
        }
        p {
          color: #4a5568;
          font-size: 16px;
          line-height: 1.6;
          margin-bottom: 32px;
        }
        .error-message {
          background: #fff5f5;
          border: 1px solid #feb2b2;
          border-radius: 10px;
          padding: 16px;
          color: #c53030;
          margin-bottom: 24px;
          font-size: 14px;
        }
        .button {
          display: inline-block;
          background: linear-gradient(135deg, #f56565 0%, #c53030 100%);
          color: white;
          text-decoration: none;
          padding: 14px 32px;
          border-radius: 10px;
          font-weight: 600;
          font-size: 16px;
          transition: transform 0.2s, box-shadow 0.2s;
          box-shadow: 0 4px 15px rgba(245, 101, 101, 0.4);
        }
        .button:hover {
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(245, 101, 101, 0.6);
        }
        .footer {
          margin-top: 24px;
          padding-top: 24px;
          border-top: 1px solid #e2e8f0;
          color: #718096;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">
          <div class="cross">✕</div>
        </div>
        <h1>Xác thực thất bại</h1>
        <div class="error-message">
          ${errorMessage}
        </div>
        <p>
          Vui lòng kiểm tra lại link xác thực hoặc yêu cầu gửi lại email xác thực từ ứng dụng.
        </p>
        <a href="#" onclick="window.close(); return false;" class="button">
          Đóng trang này
        </a>
        <div class="footer">
          © ${new Date().getFullYear()} SafeKids. All rights reserved.
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * @route   POST /api/auth/resend-verification
 * @desc    Resend verification email
 * @access  Public
 */
exports.resendVerification = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Vui lòng cung cấp email" });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });

    if (!user) {
      return res
        .status(404)
        .json({ message: "Không tìm thấy tài khoản với email này" });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: "Email đã được xác thực rồi" });
    }

    // Generate new verification token
    const verificationToken = crypto.randomBytes(32).toString("hex");
    const hashedToken = crypto
      .createHash("sha256")
      .update(verificationToken)
      .digest("hex");

    user.emailVerificationToken = hashedToken;
    user.emailVerificationExpires = Date.now() + 86400000; // 24 hours
    await user.save();

    // Send verification email
    if (!emailService.isConfigured) {
      return res.status(503).json({
        message: "Dịch vụ email chưa được cấu hình",
      });
    }

    await emailService.sendVerificationEmail(
      user.email,
      verificationToken,
      user.fullName || user.name
    );

    res.json({
      success: true,
      message: "Email xác thực đã được gửi lại. Vui lòng kiểm tra hộp thư.",
    });
  } catch (error) {
    console.error("Resend verification error:", error);
    res.status(500).json({
      message: error.message || "Không thể gửi lại email. Vui lòng thử lại",
    });
  }
};
module.exports = exports;
