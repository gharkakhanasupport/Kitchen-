-- ============================================================
-- RUN THIS ON USER DB: https://supabase.com/dashboard/project/mwnpwuxrbaousgwgoyco/sql/new
-- ============================================================

-- Drop if partially created (clean slate)
DROP TABLE IF EXISTS public.subscribers CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.daily_menus CASCADE;
DROP TABLE IF EXISTS public.menu_items CASCADE;
DROP TABLE IF EXISTS public.kitchens CASCADE;

-- 1. KITCHENS TABLE
CREATE TABLE public.kitchens (
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
CREATE INDEX idx_kitchens_cook_id ON public.kitchens(cook_id);
CREATE INDEX idx_kitchens_available ON public.kitchens(is_available);

-- 2. MENU ITEMS TABLE
CREATE TABLE public.menu_items (
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
CREATE INDEX idx_menu_items_cook_id ON public.menu_items(cook_id);
CREATE INDEX idx_menu_items_category ON public.menu_items(category);

-- 3. DAILY MENUS TABLE
CREATE TABLE public.daily_menus (
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
CREATE INDEX idx_daily_menus_cook_date ON public.daily_menus(cook_id, date);

-- 4. ORDERS TABLE
CREATE TABLE public.orders (
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
CREATE INDEX idx_orders_cook_id ON public.orders(cook_id);
CREATE INDEX idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX idx_orders_status ON public.orders(status);

-- 5. SUBSCRIBERS TABLE
CREATE TABLE public.subscribers (
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
CREATE INDEX idx_subscribers_cook_id ON public.subscribers(cook_id);

-- 6. RLS POLICIES (allow all for now)
ALTER TABLE public.kitchens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "kitchens_all" ON public.kitchens FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "menu_items_all" ON public.menu_items FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.daily_menus ENABLE ROW LEVEL SECURITY;
CREATE POLICY "daily_menus_all" ON public.daily_menus FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_all" ON public.orders FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subscribers_all" ON public.subscribers FOR ALL USING (true) WITH CHECK (true);

-- 7. AUTO-UPDATE TRIGGER
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_kitchens_updated_at BEFORE UPDATE ON public.kitchens
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_daily_menus_updated_at BEFORE UPDATE ON public.daily_menus
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_subscribers_updated_at BEFORE UPDATE ON public.subscribers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 8. ENABLE REALTIME
ALTER publication supabase_realtime ADD TABLE public.kitchens;
ALTER publication supabase_realtime ADD TABLE public.menu_items;
ALTER publication supabase_realtime ADD TABLE public.daily_menus;
ALTER publication supabase_realtime ADD TABLE public.orders;
ALTER publication supabase_realtime ADD TABLE public.subscribers;
