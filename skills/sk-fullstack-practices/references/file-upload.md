# File Upload Patterns

Load this reference when implementing file upload functionality.

---

## Option A: Presigned URL (Recommended for Large Files)

```
Client → GET /api/uploads/presign?filename=photo.jpg&type=image/jpeg
Server → { uploadUrl: "https://s3.../presigned", fileKey: "uploads/abc123.jpg" }
Client → PUT uploadUrl (direct to S3, bypasses your server)
Client → POST /api/photos { fileKey: "uploads/abc123.jpg" }  (save reference)
```

**Backend:**
```typescript
app.get('/api/uploads/presign', authenticate, async (req, res) => {
  const { filename, type } = req.query;
  const key = `uploads/${crypto.randomUUID()}-${filename}`;
  const url = await s3.getSignedUrl('putObject', {
    Bucket: process.env.S3_BUCKET, Key: key,
    ContentType: type, Expires: 300,  // 5 min
  });
  res.json({ uploadUrl: url, fileKey: key });
});
```

**Frontend:**
```typescript
async function uploadFile(file: File) {
  const { uploadUrl, fileKey } = await apiClient.get<PresignResponse>(
    `/api/uploads/presign?filename=${file.name}&type=${file.type}`
  );
  await fetch(uploadUrl, { method: 'PUT', body: file, headers: { 'Content-Type': file.type } });
  return apiClient.post('/api/photos', { fileKey });
}
```

## Option B: Multipart (Small Files < 10MB)

```typescript
// Frontend
const formData = new FormData();
formData.append('file', file);
formData.append('description', 'Profile photo');
const res = await fetch('/api/upload', { method: 'POST', body: formData });
// Note: do NOT set Content-Type header — browser sets boundary automatically
```

## Decision

| Method | File Size | Server Load | Complexity |
|--------|-----------|-------------|------------|
| Presigned URL | Any (recommended > 5MB) | None (direct to storage) | Medium |
| Multipart | < 10MB | High (streams through server) | Low |
| Chunked / Resumable | > 100MB | Medium | High |
