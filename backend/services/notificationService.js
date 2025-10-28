let twilioClient = null;
const DEFAULT_COUNTRY_CODE = process.env.DEFAULT_SMS_COUNTRY_CODE || '+251';

function initTwilio() {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_FROM_NUMBER;
  if (sid && token && from) {
    try {
      // Lazy require to avoid hard dependency if not configured
      // eslint-disable-next-line global-require
      const Twilio = require('twilio');
      twilioClient = new Twilio(sid, token);
      return true;
    } catch (e) {
      twilioClient = null;
      return false;
    }
  }
  return false;
}

async function sendSms(to, body) {
  if (!twilioClient && !initTwilio()) {
    return { success: false, error: 'Twilio not configured' };
  }
  try {
    const from = process.env.TWILIO_FROM_NUMBER;
    await twilioClient.messages.create({ to, from, body });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

function normalizeE164(phoneRaw) {
  if (!phoneRaw) return phoneRaw;
  let p = phoneRaw.replace(/\s|-/g, '');
  if (p.startsWith('+')) return p;
  if (p.startsWith('00')) return `+${p.substring(2)}`;
  // Ethiopia basic normalization heuristics
  if (p.startsWith('0')) return `${DEFAULT_COUNTRY_CODE}${p.substring(1)}`; // 0XXXXXXXXX -> +251XXXXXXXXX
  if (p.startsWith('251')) return `+${p}`;
  if (p.length === 9) return `${DEFAULT_COUNTRY_CODE}${p}`;
  return `+${p}`;
}

async function sendSmsNormalized(to, body) {
  const normalized = normalizeE164(to);
  return sendSms(normalized, body);
}

module.exports = { sendSms, sendSmsNormalized, normalizeE164 };


