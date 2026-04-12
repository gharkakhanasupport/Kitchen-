-- ============================================================
-- RUN THIS SQL IN SUPABASE DASHBOARD → SQL EDITOR
-- Run on Kitchen DB: https://supabase.com/dashboard/project/yvbjnuobnxekgibfqsmq/sql
-- Then ALSO run on User DB: https://supabase.com/dashboard/project/mwnpwuxrbaousgwgoyco/sql
-- ============================================================

-- 1. KITCHENS TABLE
CREATE TABLE IF NOT EXISTS public.kitchens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cook_id TEXT NOT NULL UNIQUE,
  kitchen_name TEXT NOT NULL,
  description TEXT,
  owner_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  location TEXT,
  is_vegetarian BOOLEAN DEFAULT false,
  kitchen_photos TEXT[] DEFAULT '{}',
  is_available BOOLEAN DEFAULT true,
  rating DOUBLE PRECISION DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_kitchens_cook_id ON public.kitchens(cook_id);
CREATE INDEX IF NOT EXISTS idx_kitchens_available ON public.kitchens(is_available);
ALTER TABLE public.kitchens ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "kitchens_select" ON public.kitchens FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "kitchens_insert" ON public.kitchens FOR INSERT WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "kitchens_update" ON public.kitchens FOR UPDATE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "kitchens_delete" ON public.kitchens FOR DELETE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. MENU ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cook_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  price DOUBLE PRECISION NOT NULL,
  quantity_available INTEGER DEFAULT 0,
  category TEXT NOT NULL,
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_menu_items_cook_id ON public.menu_items(cook_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON public.menu_items(is_available);
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "menu_items_select" ON public.menu_items FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "menu_items_insert" ON public.menu_items FOR INSERT WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "menu_items_update" ON public.menu_items FOR UPDATE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "menu_items_delete" ON public.menu_items FOR DELETE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 3. DAILY MENUS TABLE
CREATE TABLE IF NOT EXISTS public.daily_menus (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cook_id TEXT NOT NULL,
  date DATE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  category TEXT NOT NULL,
  price DOUBLE PRECISION NOT NULL,
  quantity INTEGER DEFAULT 0,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(cook_id, date, name)
);
CREATE INDEX IF NOT EXISTS idx_daily_menus_cook_date ON public.daily_menus(cook_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_menus_date ON public.daily_menus(date);
ALTER TABLE public.daily_menus ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "daily_menus_select" ON public.daily_menus FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "daily_menus_insert" ON public.daily_menus FOR INSERT WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "daily_menus_update" ON public.daily_menus FOR UPDATE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "daily_menus_delete" ON public.daily_menus FOR DELETE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 4. ORDERS TABLE
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cook_id TEXT NOT NULL,
  customer_id TEXT,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  delivery_address TEXT,
  items JSONB NOT NULL DEFAULT '[]',
  total_amount DOUBLE PRECISION NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_orders_cook_id ON public.orders(cook_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "orders_select" ON public.orders FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "orders_insert" ON public.orders FOR INSERT WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "orders_update" ON public.orders FOR UPDATE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "orders_delete" ON public.orders FOR DELETE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 5. SUBSCRIBERS TABLE
CREATE TABLE IF NOT EXISTS public.subscribers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cook_id TEXT NOT NULL,
  customer_id TEXT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  profile_image_url TEXT,
  plan_type TEXT NOT NULL DEFAULT 'monthly',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  todays_meal TEXT,
  meal_quantity INTEGER DEFAULT 1,
  meal_status TEXT DEFAULT 'scheduled',
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_subscribers_cook_id ON public.subscribers(cook_id);
CREATE INDEX IF NOT EXISTS idx_subscribers_customer_id ON public.subscribers(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscribers_status ON public.subscribers(status);
ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "subscribers_select" ON public.subscribers FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "subscribers_insert" ON public.subscribers FOR INSERT WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "subscribers_update" ON public.subscribers FOR UPDATE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "subscribers_delete" ON public.subscribers FOR DELETE USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 6. AUTO-UPDATE TRIGGER
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_kitchens_updated_at ON public.kitchens;
CREATE TRIGGER update_kitchens_updated_at BEFORE UPDATE ON public.kitchens
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_menu_items_updated_at ON public.menu_items;
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_menus_updated_at ON public.daily_menus;
CREATE TRIGGER update_daily_menus_updated_at BEFORE UPDATE ON public.daily_menus
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscribers_updated_at ON public.subscribers;
CREATE TRIGGER update_subscribers_updated_at BEFORE UPDATE ON public.subscribers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 7. ENABLE REALTIME (safe - ignores if already added)
DO $$ BEGIN
  ALTER publication supabase_realtime ADD TABLE public.kitchens;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER publication supabase_realtime ADD TABLE public.menu_items;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER publication supabase_realtime ADD TABLE public.daily_menus;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER publication supabase_realtime ADD TABLE public.orders;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER publication supabase_realtime ADD TABLE public.subscribers;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
