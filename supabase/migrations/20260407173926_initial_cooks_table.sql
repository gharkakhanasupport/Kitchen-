-- Cooks / Kitchen owners signup table
-- Stores all data from the 3-step signup form

CREATE TABLE public.cooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Step 1: Personal Details
  full_name TEXT NOT NULL,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL DEFAULT 'MALE',
  location TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL,
  email TEXT NOT NULL DEFAULT '',

  -- Step 2: KYC Verification
  aadhar_front_url TEXT,
  aadhar_back_url TEXT,
  pan_card_url TEXT,

  -- Step 3: Kitchen Details
  kitchen_name TEXT NOT NULL DEFAULT '',
  kitchen_description TEXT NOT NULL DEFAULT '',
  nominee_partner TEXT NOT NULL DEFAULT '',
  is_vegetarian BOOLEAN NOT NULL DEFAULT true,
  kitchen_photos TEXT[] DEFAULT '{}',

  -- Metadata
  is_available BOOLEAN NOT NULL DEFAULT true,
  rating DOUBLE PRECISION NOT NULL DEFAULT 0,
  total_orders INTEGER NOT NULL DEFAULT 0,
  earnings DOUBLE PRECISION NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending_review',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cooks_phone ON public.cooks(phone);
CREATE INDEX idx_cooks_email ON public.cooks(email);

-- Allow anyone to insert (signup without auth for now)
ALTER TABLE public.cooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public inserts for signup"
  ON public.cooks FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow public reads"
  ON public.cooks FOR SELECT
  USING (true);

CREATE POLICY "Allow public updates"
  ON public.cooks FOR UPDATE
  USING (true);
