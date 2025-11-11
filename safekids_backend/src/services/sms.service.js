/**
 * SMS Service - Twilio Verify API
 * Sends verification codes using Twilio Verify API
 */

const twilio = require('twilio');

class SMSService {
  constructor() {
    this.client = null;
    this.isConfigured = false;
    this.verifyServiceSid = null;
  }

  /**
   * Initialize Twilio Verify client
   */
  init() {
    const { 
      TWILIO_ACCOUNT_SID, 
      TWILIO_AUTH_TOKEN, 
      TWILIO_VERIFY_SERVICE_SID 
    } = process.env;

    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN) {
      console.warn('⚠️ SMS service not configured: Missing Twilio Account SID or Auth Token in .env');
      return;
    }

    if (!TWILIO_VERIFY_SERVICE_SID) {
      console.warn('⚠️ SMS service not configured: Missing TWILIO_VERIFY_SERVICE_SID in .env');
      return;
    }

    try {
      this.client = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
      this.verifyServiceSid = TWILIO_VERIFY_SERVICE_SID;
      this.isConfigured = true;
      console.log(`✅ SMS service initialized with Twilio Verify API: ${TWILIO_VERIFY_SERVICE_SID}`);
    } catch (error) {
      console.error('❌ Failed to initialize SMS service:', error.message);
    }
  }

  /**
   * Send verification code via SMS using Twilio Verify API
   * @param {string} phoneNumber - Recipient phone number (E.164 format: +84xxxxxxxxx)
   * @returns {Promise<{success: boolean, sid?: string}>}
   */
  async sendVerificationCode(phoneNumber) {
    if (!this.isConfigured) {
      throw new Error('SMS service is not configured. Please check Twilio Verify credentials in .env');
    }

    // Normalize phone number to E.164 format
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);

    try {
      const verification = await this.client.verify.v2
        .services(this.verifyServiceSid)
        .verifications
        .create({
          to: normalizedPhone,
          channel: 'sms',
          locale: 'vi' // Vietnamese language
        });

      console.log(`✅ Verification code sent to ${normalizedPhone}: ${verification.sid}`);
      return { success: true, sid: verification.sid, status: verification.status };
    } catch (error) {
      console.error('❌ Failed to send verification code:', error.message);
      
      // Handle specific Twilio Verify errors
      if (error.code === 60200) {
        throw new Error('Số điện thoại không hợp lệ');
      } else if (error.code === 60202) {
        throw new Error('Đã gửi quá nhiều mã. Vui lòng thử lại sau.');
      } else if (error.code === 60203) {
        throw new Error('Số điện thoại không thể nhận tin nhắn');
      }
      
      throw new Error('Không thể gửi mã xác thực. Vui lòng thử lại sau.');
    }
  }

  /**
   * Verify OTP code using Twilio Verify API
   * @param {string} phoneNumber - Phone number to verify
   * @param {string} code - Verification code (OTP)
   * @returns {Promise<{success: boolean, status?: string}>}
   */
  async verifyCode(phoneNumber, code) {
    if (!this.isConfigured) {
      throw new Error('SMS service is not configured. Please check Twilio Verify credentials in .env');
    }

    // Normalize phone number to E.164 format
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);

    try {
      const verificationCheck = await this.client.verify.v2
        .services(this.verifyServiceSid)
        .verificationChecks
        .create({
          to: normalizedPhone,
          code: code
        });

      if (verificationCheck.status === 'approved') {
        console.log(`✅ Verification successful for ${normalizedPhone}`);
        return { success: true, status: verificationCheck.status };
      } else {
        console.warn(`⚠️ Verification failed for ${normalizedPhone}: ${verificationCheck.status}`);
        return { success: false, status: verificationCheck.status };
      }
    } catch (error) {
      console.error('❌ Failed to verify code:', error.message);
      
      // Handle specific Twilio Verify errors
      if (error.code === 60200) {
        throw new Error('Số điện thoại không hợp lệ');
      } else if (error.code === 60202) {
        throw new Error('Mã xác thực không chính xác');
      } else if (error.code === 60203) {
        throw new Error('Mã xác thực đã hết hạn');
      }
      
      throw new Error('Không thể xác thực mã. Vui lòng thử lại.');
    }
  }

  /**
   * Normalize phone number to E.164 format
   * Converts Vietnamese phone numbers to international format
   * @param {string} phone - Phone number (e.g., "0912345678" or "84912345678")
   * @returns {string} E.164 formatted phone (e.g., "+84912345678")
   */
  normalizePhoneNumber(phone) {
    // Remove all non-digit characters
    let digits = phone.replace(/\D/g, '');

    // If starts with 0, replace with country code 84 (Vietnam)
    if (digits.startsWith('0')) {
      digits = '84' + digits.substring(1);
    }

    // Add + prefix if not present
    if (!digits.startsWith('+')) {
      digits = '+' + digits;
    }

    return digits;
  }

  /**
   * Verify SMS service is working
   */
  async verifyConnection() {
    if (!this.isConfigured) {
      return { success: false, message: 'SMS service not configured' };
    }

    try {
      // Try to fetch account info to verify credentials
      await this.client.api.accounts(process.env.TWILIO_ACCOUNT_SID).fetch();
      return { success: true, message: 'SMS service is ready' };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }
}

module.exports = new SMSService();
