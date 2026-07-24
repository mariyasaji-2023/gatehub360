const express = require('express');
const requireAuth = require('../middleware/auth');
const Service = require('../models/Service');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  const filter = { active: true };
  if (req.query.category) filter.categorySlug = req.query.category;
  const services = await Service.find(filter).sort({ createdAt: -1 });
  res.json({ services });
});

router.get('/mine', requireAuth, async (req, res) => {
  const services = await Service.find({ provider: req.user._id }).sort({ createdAt: -1 });
  res.json({ services });
});

router.post('/', requireAuth, async (req, res) => {
  if (req.user.role !== 'service_provider') {
    return res.status(403).json({ message: 'Only service providers can add services' });
  }

  const { categorySlug, price, desc, active } = req.body;
  if (!Service.CATEGORIES.includes(categorySlug)) {
    return res.status(400).json({ message: 'Invalid category' });
  }
  if (!price || !desc) {
    return res.status(400).json({ message: 'Price and description are required' });
  }

  try {
    const service = await Service.create({
      provider: req.user._id,
      providerName: req.user.name || 'Service Provider',
      categorySlug,
      price,
      desc,
      active: active ?? true,
    });
    res.status(201).json({ service });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: "You've already listed this category" });
    }
    throw err;
  }
});

router.patch('/:id', requireAuth, async (req, res) => {
  const service = await Service.findOne({ _id: req.params.id, provider: req.user._id });
  if (!service) {
    return res.status(404).json({ message: 'Service not found' });
  }

  const { price, desc, active } = req.body;
  if (price !== undefined) service.price = price;
  if (desc !== undefined) service.desc = desc;
  if (active !== undefined) service.active = active;
  await service.save();
  res.json({ service });
});

router.delete('/:id', requireAuth, async (req, res) => {
  const result = await Service.deleteOne({ _id: req.params.id, provider: req.user._id });
  if (result.deletedCount === 0) {
    return res.status(404).json({ message: 'Service not found' });
  }
  res.json({ success: true });
});

module.exports = router;
