export const isEmail = (value: string): boolean =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);

export const isStrongPassword = (value: string): boolean =>
  /(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}/.test(value);
