const db = require('../services/firebase');
const Exercice = require('../models/exercice.model');

exports.getAll = async (req, res) => {
  const snap = await db.collection('exercices').get();
  const exercices = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  res.json(exercices);
};

exports.create = async (req, res) => {
  const exercice = new Exercice(req.body);
  const ref = await db.collection('exercices').add(exercice);
  res.json({ id: ref.id });
};
