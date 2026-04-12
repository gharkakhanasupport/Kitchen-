-- Add password field to cooks table (Step 4 of signup)
ALTER TABLE public.cooks ADD COLUMN password TEXT NOT NULL DEFAULT '';
