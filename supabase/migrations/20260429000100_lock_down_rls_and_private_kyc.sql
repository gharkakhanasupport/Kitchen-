-- ============================================================
-- Production hardening: lock down public RLS and private KYC
-- ============================================================
-- This migration intentionally removes public write/delete access.
-- Server-side jobs using the service role still bypass RLS.

-- Shared role helpers. Put admin/super-admin claims into app_metadata.role.
CREATE OR REPLACE FUNCTION public.gkk_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', '') IN (
    'admin',
    'super_admin',
    'support_admin'
  )
  OR COALESCE(auth.jwt() ->> 'role', '') IN (
    'admin',
    'super_admin',
    'support_admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.gkk_owns_cook(p_cook_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid() IS NOT NULL
    AND (
      auth.uid()::text = p_cook_id
      OR EXISTS (
        SELECT 1
        FROM public.cooks c
        WHERE c.id::text = p_cook_id
          AND lower(c.email) = lower(COALESCE(auth.jwt() ->> 'email', ''))
      )
    );
$$;

-- ============================================================
-- Cooks table: no public reads/updates. Signup must be authenticated
-- or handled by a backend/service-role function.
-- ============================================================
DROP POLICY IF EXISTS "Allow public inserts for signup" ON public.cooks;
DROP POLICY IF EXISTS "Allow public reads" ON public.cooks;
DROP POLICY IF EXISTS "Allow public updates" ON public.cooks;

CREATE POLICY "cooks_insert_self_or_admin"
  ON public.cooks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.gkk_is_admin()
    OR lower(email) = lower(COALESCE(auth.jwt() ->> 'email', ''))
  );

CREATE POLICY "cooks_select_self_or_admin"
  ON public.cooks
  FOR SELECT
  TO authenticated
  USING (
    public.gkk_is_admin()
    OR id = auth.uid()
    OR lower(email) = lower(COALESCE(auth.jwt() ->> 'email', ''))
  );

CREATE POLICY "cooks_update_self_or_admin"
  ON public.cooks
  FOR UPDATE
  TO authenticated
  USING (
    public.gkk_is_admin()
    OR id = auth.uid()
    OR lower(email) = lower(COALESCE(auth.jwt() ->> 'email', ''))
  )
  WITH CHECK (
    public.gkk_is_admin()
    OR id = auth.uid()
    OR lower(email) = lower(COALESCE(auth.jwt() ->> 'email', ''))
  );

CREATE POLICY "cooks_delete_admin_only"
  ON public.cooks
  FOR DELETE
  TO authenticated
  USING (public.gkk_is_admin());

-- ============================================================
-- Public catalogue tables: public SELECT is OK for customer browsing,
-- but all writes are owner/admin/backend only.
-- ============================================================
DROP POLICY IF EXISTS "kitchens_select" ON public.kitchens;
DROP POLICY IF EXISTS "kitchens_insert" ON public.kitchens;
DROP POLICY IF EXISTS "kitchens_update" ON public.kitchens;
DROP POLICY IF EXISTS "kitchens_delete" ON public.kitchens;

CREATE POLICY "kitchens_public_read_available"
  ON public.kitchens
  FOR SELECT
  USING (is_available = true OR public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "kitchens_insert_owner_or_admin"
  ON public.kitchens
  FOR INSERT
  TO authenticated
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "kitchens_update_owner_or_admin"
  ON public.kitchens
  FOR UPDATE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin())
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "kitchens_delete_admin_only"
  ON public.kitchens
  FOR DELETE
  TO authenticated
  USING (public.gkk_is_admin());

DROP POLICY IF EXISTS "menu_items_select" ON public.menu_items;
DROP POLICY IF EXISTS "menu_items_insert" ON public.menu_items;
DROP POLICY IF EXISTS "menu_items_update" ON public.menu_items;
DROP POLICY IF EXISTS "menu_items_delete" ON public.menu_items;

CREATE POLICY "menu_items_public_read_available"
  ON public.menu_items
  FOR SELECT
  USING (is_available = true OR public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "menu_items_insert_owner_or_admin"
  ON public.menu_items
  FOR INSERT
  TO authenticated
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "menu_items_update_owner_or_admin"
  ON public.menu_items
  FOR UPDATE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin())
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "menu_items_delete_owner_or_admin"
  ON public.menu_items
  FOR DELETE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

DROP POLICY IF EXISTS "daily_menus_select" ON public.daily_menus;
DROP POLICY IF EXISTS "daily_menus_insert" ON public.daily_menus;
DROP POLICY IF EXISTS "daily_menus_update" ON public.daily_menus;
DROP POLICY IF EXISTS "daily_menus_delete" ON public.daily_menus;

CREATE POLICY "daily_menus_public_read_available"
  ON public.daily_menus
  FOR SELECT
  USING (is_available = true OR public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "daily_menus_insert_owner_or_admin"
  ON public.daily_menus
  FOR INSERT
  TO authenticated
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "daily_menus_update_owner_or_admin"
  ON public.daily_menus
  FOR UPDATE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin())
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "daily_menus_delete_owner_or_admin"
  ON public.daily_menus
  FOR DELETE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

-- ============================================================
-- Orders/subscribers: no public access. Customers see their own,
-- cooks see their kitchen's rows, admins see all.
-- ============================================================
DROP POLICY IF EXISTS "orders_select" ON public.orders;
DROP POLICY IF EXISTS "orders_insert" ON public.orders;
DROP POLICY IF EXISTS "orders_update" ON public.orders;
DROP POLICY IF EXISTS "orders_delete" ON public.orders;

CREATE POLICY "orders_select_participant_or_admin"
  ON public.orders
  FOR SELECT
  TO authenticated
  USING (
    customer_id = auth.uid()::text
    OR public.gkk_owns_cook(cook_id)
    OR public.gkk_is_admin()
  );

CREATE POLICY "orders_insert_customer_or_admin"
  ON public.orders
  FOR INSERT
  TO authenticated
  WITH CHECK (
    customer_id = auth.uid()::text
    OR public.gkk_is_admin()
  );

CREATE POLICY "orders_update_cook_or_admin"
  ON public.orders
  FOR UPDATE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin())
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "orders_delete_admin_only"
  ON public.orders
  FOR DELETE
  TO authenticated
  USING (public.gkk_is_admin());

DROP POLICY IF EXISTS "subscribers_select" ON public.subscribers;
DROP POLICY IF EXISTS "subscribers_insert" ON public.subscribers;
DROP POLICY IF EXISTS "subscribers_update" ON public.subscribers;
DROP POLICY IF EXISTS "subscribers_delete" ON public.subscribers;

CREATE POLICY "subscribers_select_participant_or_admin"
  ON public.subscribers
  FOR SELECT
  TO authenticated
  USING (
    customer_id = auth.uid()::text
    OR public.gkk_owns_cook(cook_id)
    OR public.gkk_is_admin()
  );

CREATE POLICY "subscribers_insert_cook_or_admin"
  ON public.subscribers
  FOR INSERT
  TO authenticated
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "subscribers_update_cook_or_admin"
  ON public.subscribers
  FOR UPDATE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin())
  WITH CHECK (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

CREATE POLICY "subscribers_delete_cook_or_admin"
  ON public.subscribers
  FOR DELETE
  TO authenticated
  USING (public.gkk_owns_cook(cook_id) OR public.gkk_is_admin());

-- ============================================================
-- Storage: KYC private. Kitchen photos can stay public for menu/profile
-- display, but upload/delete is restricted to authenticated users.
-- ============================================================
UPDATE storage.buckets
SET public = false
WHERE id = 'kyc-documents';

UPDATE storage.buckets
SET public = true
WHERE id = 'kitchen-photos';

DROP POLICY IF EXISTS "Public upload kyc documents" ON storage.objects;
DROP POLICY IF EXISTS "Public read kyc documents" ON storage.objects;
DROP POLICY IF EXISTS "Public upload kitchen photos" ON storage.objects;
DROP POLICY IF EXISTS "Public read kitchen photos" ON storage.objects;

CREATE POLICY "kyc_documents_insert_owner_or_admin"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND (
      public.gkk_is_admin()
      OR owner = auth.uid()
      OR (storage.foldername(name))[1] = auth.uid()::text
    )
  );

CREATE POLICY "kyc_documents_select_owner_or_admin"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND (
      public.gkk_is_admin()
      OR owner = auth.uid()
      OR (storage.foldername(name))[1] = auth.uid()::text
    )
  );

CREATE POLICY "kyc_documents_update_owner_or_admin"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND (
      public.gkk_is_admin()
      OR owner = auth.uid()
      OR (storage.foldername(name))[1] = auth.uid()::text
    )
  )
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND (
      public.gkk_is_admin()
      OR owner = auth.uid()
      OR (storage.foldername(name))[1] = auth.uid()::text
    )
  );

CREATE POLICY "kyc_documents_delete_owner_or_admin"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND (
      public.gkk_is_admin()
      OR owner = auth.uid()
      OR (storage.foldername(name))[1] = auth.uid()::text
    )
  );

CREATE POLICY "kitchen_photos_public_read"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'kitchen-photos');

CREATE POLICY "kitchen_photos_insert_authenticated"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'kitchen-photos');

CREATE POLICY "kitchen_photos_update_owner_or_admin"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'kitchen-photos'
    AND (public.gkk_is_admin() OR owner = auth.uid())
  )
  WITH CHECK (
    bucket_id = 'kitchen-photos'
    AND (public.gkk_is_admin() OR owner = auth.uid())
  );

CREATE POLICY "kitchen_photos_delete_owner_or_admin"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'kitchen-photos'
    AND (public.gkk_is_admin() OR owner = auth.uid())
  );
