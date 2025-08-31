import { Request, Response, NextFunction } from 'express';
import { Schema } from 'joi';

// Validate body for JSON
export const validateBody = (schema: Schema) => (
  req: Request, res: Response, next: NextFunction
) => {
  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};
