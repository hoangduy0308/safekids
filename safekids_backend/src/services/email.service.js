/**
 * Email Service - Gmail SMTP
 * Sends emails using Gmail SMTP with App Password
 */

const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.isConfigured = false;
  }

  /**
   * Initialize email transporter with Gmail SMTP
   */
  init() {
    const { GMAIL_USER, GMAIL_APP_PASSWORD } = process.env;

    if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
      console.warn('⚠️ Email service not configured: Missing GMAIL_USER or GMAIL_APP_PASSWORD in .env');
      return;
    }

    try {
      this.transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: GMAIL_USER,
          pass: GMAIL_APP_PASSWORD,
        },
      });

      this.isConfigured = true;
      console.log('✅ Email service initialized with Gmail SMTP');
    } catch (error) {
      console.error('❌ Failed to initialize email service:', error.message);
    }
  }

  /**
   * Send OTP email for password reset
   * @param {string} email - Recipient email
   * @param {string} otp - 6-digit OTP code
   * @param {string} userName - User's name for personalization
   */
  async sendPasswordResetOTP(email, otp, userName = '') {
    if (!this.isConfigured) {
      throw new Error('Email service is not configured. Please check .env settings.');
    }

    const mailOptions = {
      from: `SafeKids App <${process.env.GMAIL_USER}>`,
      to: email,
      subject: 'Mã xác thực đặt lại mật khẩu - SafeKids',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .otp-box { background: white; border: 2px dashed #667eea; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px; }
            .otp-code { font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; font-family: 'Courier New', monospace; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
            .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🛡️ SafeKids</h1>
              <p>Đặt lại mật khẩu</p>
            </div>
            <div class="content">
              <p>Xin chào ${userName || 'bạn'},</p>
              <p>Bạn đã yêu cầu đặt lại mật khẩu cho tài khoản SafeKids của mình.</p>
              
              <div class="otp-box">
                <p style="margin: 0 0 10px 0; color: #666;">Mã xác thực của bạn là:</p>
                <div class="otp-code">${otp}</div>
              </div>

              <div class="warning">
                <strong>⚠️ Lưu ý:</strong>
                <ul style="margin: 10px 0 0 0; padding-left: 20px;">
                  <li>Mã này có hiệu lực trong <strong>15 phút</strong></li>
                  <li>Không chia sẻ mã này với bất kỳ ai</li>
                  <li>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này</li>
                </ul>
              </div>

              <p>Trân trọng,<br><strong>Đội ngũ SafeKids</strong></p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} SafeKids. All rights reserved.</p>
              <p>Email này được gửi tự động, vui lòng không trả lời.</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `
        SafeKids - Đặt lại mật khẩu
        
        Xin chào ${userName || 'bạn'},
        
        Mã xác thực của bạn là: ${otp}
        
        Mã này có hiệu lực trong 15 phút.
        Không chia sẻ mã này với bất kỳ ai.
        
        Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.
        
        Trân trọng,
        Đội ngũ SafeKids
      `,
    };

    try {
      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ Password reset email sent to ${email}: ${info.messageId}`);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('❌ Failed to send email:', error.message);
      throw new Error('Không thể gửi email. Vui lòng thử lại sau.');
    }
  }

  /**
   * Send email verification link
   * @param {string} email - Recipient email
   * @param {string} token - Verification token
   * @param {string} userName - User's name for personalization
   */
  async sendVerificationEmail(email, token, userName = '') {
    if (!this.isConfigured) {
      throw new Error('Email service is not configured. Please check .env settings.');
    }

    // Generate verification link (backend endpoint)
    const backendUrl = process.env.BACKEND_URL || 'http://localhost:3000';
    const verificationLink = `${backendUrl}/api/auth/verify-email?token=${token}`;

    const mailOptions = {
      from: `SafeKids App <${process.env.GMAIL_USER}>`,
      to: email,
      subject: 'Xác thực tài khoản SafeKids của bạn',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { display: inline-block; padding: 15px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 8px; font-weight: bold; margin: 20px 0; }
            .button:hover { background: #5568d3; }
            .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🛡️ SafeKids</h1>
              <p>Chào mừng bạn!</p>
            </div>
            <div class="content">
              <p>Xin chào ${userName || 'bạn'},</p>
              <p>Cảm ơn bạn đã đăng ký tài khoản SafeKids! Vui lòng xác thực email của bạn để kích hoạt tài khoản.</p>
              
              <div style="text-align: center;">
                <a href="${verificationLink}" class="button">Xác thực Email</a>
              </div>

              <p style="color: #666; font-size: 14px;">
                Hoặc copy link sau vào trình duyệt:
              </p>
              
              <p style="background: white; padding: 10px; border-radius: 5px; word-break: break-all; font-size: 12px;">
                ${verificationLink}
              </p>

              <div class="warning">
                <strong>⚠️ Lưu ý:</strong>
                <ul style="margin: 10px 0 0 0; padding-left: 20px;">
                  <li>Link này có hiệu lực trong <strong>24 giờ</strong></li>
                  <li>Nếu bạn không yêu cầu đăng ký, vui lòng bỏ qua email này</li>
                  <li>Không chia sẻ link này với bất kỳ ai</li>
                </ul>
              </div>

              <p>Trân trọng,<br><strong>Đội ngũ SafeKids</strong></p>
            </div>
            <div class="footer">
              <p>© ${new Date().getFullYear()} SafeKids. All rights reserved.</p>
              <p>Email này được gửi tự động, vui lòng không trả lời.</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `
        SafeKids - Xác thực email
        
        Xin chào ${userName || 'bạn'},
        
        Cảm ơn bạn đã đăng ký tài khoản SafeKids! 
        
        Vui lòng xác thực email bằng cách truy cập link sau:
        ${verificationLink}
        
        Link này có hiệu lực trong 24 giờ.
        
        Nếu bạn không yêu cầu đăng ký, vui lòng bỏ qua email này.
        
        Trân trọng,
        Đội ngũ SafeKids
      `,
    };

    try {
      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ Verification email sent to ${email}: ${info.messageId}`);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('❌ Failed to send verification email:', error.message);
      throw new Error('Không thể gửi email xác thực. Vui lòng thử lại sau.');
    }
  }

  /**
   * Verify email service is working
   */
  async verifyConnection() {
    if (!this.isConfigured) {
      return { success: false, message: 'Email service not configured' };
    }

    try {
      await this.transporter.verify();
      return { success: true, message: 'Email service is ready' };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }
}

module.exports = new EmailService();
