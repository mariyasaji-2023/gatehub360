const express = require('express');
const crypto = require('crypto');
const Razorpay = require('razorpay');
const requireAuth = require('../middleware/auth');

const router = express.Router();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// amount is in rupees; Razorpay orders are created in paise.
router.post('/order', requireAuth, async (req, res) => {
  const { amount, receipt } = req.body;
  if (!amount || amount <= 0) {
    return res.status(400).json({ message: 'Invalid amount' });
  }

  const order = await razorpay.orders.create({
    amount: Math.round(amount * 100),
    currency: 'INR',
    receipt: receipt || `rcpt_${Date.now()}`,
  });

  res.json({
    orderId: order.id,
    amount: order.amount,
    currency: order.currency,
    keyId: process.env.RAZORPAY_KEY_ID,
  });
});

router.post('/verify', requireAuth, async (req, res) => {
  const { razorpay_order_id: orderId, razorpay_payment_id: paymentId, razorpay_signature: signature } = req.body;
  if (!orderId || !paymentId || !signature) {
    return res.status(400).json({ message: 'Missing payment verification fields' });
  }

  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');

  res.json({ verified: expected === signature });
});

module.exports = router;
