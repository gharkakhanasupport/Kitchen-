-- Storage buckets for KYC documents and kitchen photos

INSERT INTO storage.buckets (id, name, public)
VALUES ('kyc-documents', 'kyc-documents', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('kitchen-photos', 'kitchen-photos', true)
ON CONFLICT (id) DO NOTHING;

-- KYC documents: anyone can upload and view (no auth yet)
CREATE POLICY "Public upload kyc documents"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'kyc-documents');

CREATE POLICY "Public read kyc documents"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'kyc-documents');

-- Kitchen photos: anyone can upload and view (no auth yet)
CREATE POLICY "Public upload kitchen photos"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'kitchen-photos');

CREATE POLICY "Public read kitchen photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'kitchen-photos');
