"use client";

import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { MenuInput, MenuSelect } from "@/components/menu-action-form";
import { createClient } from "@/lib/supabase/client";
import {
  getMenuImage,
  MENU_IMAGE_BUCKET,
  MENU_PHOTO_ASSETS,
} from "@/lib/menu-images";
import type { MenuCategoryName } from "@/lib/menu";

const MAX_FILE_SIZE = 5 * 1024 * 1024;
const FILE_EXTENSIONS: Record<string, string> = {
  "image/avif": "avif",
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

export function MenuPhotoInput({
  suffix,
  initialPhotoUrl,
  itemName,
  categoryName,
}: Readonly<{
  suffix: string;
  initialPhotoUrl: string;
  itemName: string;
  categoryName: MenuCategoryName;
}>) {
  const [photoUrl, setPhotoUrl] = useState(initialPhotoUrl);
  const [file, setFile] = useState<File | null>(null);
  const [filePreview, setFilePreview] = useState<string | null>(null);
  const [uploadError, setUploadError] = useState("");
  const [uploadMessage, setUploadMessage] = useState("");
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const filePreviewRef = useRef<string | null>(null);
  const isBundledAsset = MENU_PHOTO_ASSETS.some((asset) => asset.src === photoUrl);
  const preview = getMenuImage(photoUrl || null, itemName, categoryName);

  useEffect(() => {
    return () => {
      if (filePreviewRef.current) URL.revokeObjectURL(filePreviewRef.current);
    };
  }, []);

  function clearSelectedFile() {
    if (filePreviewRef.current) URL.revokeObjectURL(filePreviewRef.current);
    filePreviewRef.current = null;
    setFile(null);
    setFilePreview(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function releaseFilePreview() {
    if (filePreviewRef.current) URL.revokeObjectURL(filePreviewRef.current);
    filePreviewRef.current = null;
    setFilePreview(null);
  }

  async function uploadSelectedFile() {
    if (!file) return;
    if (!(file.type in FILE_EXTENSIONS)) {
      setUploadError("Choose a JPEG, PNG, WebP, or AVIF image.");
      return;
    }
    if (file.size > MAX_FILE_SIZE) {
      setUploadError("Images must be 5 MB or smaller.");
      return;
    }

    setUploading(true);
    setUploadError("");
    try {
      const supabase = createClient();
      const objectPath = `menu-items/${crypto.randomUUID()}.${FILE_EXTENSIONS[file.type]}`;
      const { error } = await supabase.storage
        .from(MENU_IMAGE_BUCKET)
        .upload(objectPath, file, {
          cacheControl: "3600",
          contentType: file.type,
          upsert: false,
        });

      if (error) {
        setUploadError(`Could not upload photo: ${error.message}`);
        return;
      }

      const { data } = supabase.storage.from(MENU_IMAGE_BUCKET).getPublicUrl(objectPath);
      setPhotoUrl(data.publicUrl);
      clearSelectedFile();
      setUploadMessage("Photo uploaded and selected. Save the menu item to apply it.");
    } catch (error) {
      setUploadError(
        error instanceof Error ? `Could not upload photo: ${error.message}` : "Could not upload photo.",
      );
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1.1fr)_minmax(18rem,0.9fr)]">
      <div className="space-y-5">
        <label className="grid gap-2 text-sm font-medium" htmlFor={`item-photo-${suffix}`}>
          <span>Choose an existing photo</span>
          <MenuSelect
            id={`item-photo-${suffix}`}
            name="photoUrl"
            onChange={(event) => {
              setPhotoUrl(event.currentTarget.value);
              clearSelectedFile();
              setUploadMessage("");
            }}
            value={photoUrl}
          >
            <option value="">Automatic photo by dish/category</option>
            {photoUrl && !isBundledAsset && (
              <option value={photoUrl}>Keep current uploaded photo</option>
            )}
            {MENU_PHOTO_ASSETS.map((asset) => (
              <option key={asset.src} value={asset.src}>{asset.label}</option>
            ))}
          </MenuSelect>
          <span className="text-xs font-normal text-muted-foreground">
            Select a bundled photo or upload one from this device.
          </span>
        </label>

        <div className="grid gap-2">
          <label className="text-sm font-medium" htmlFor={`item-photo-file-${suffix}`}>
            Upload from this device
          </label>
          <MenuInput
            accept="image/jpeg,image/png,image/webp,image/avif"
            className="h-auto min-h-11 file:mr-3 file:rounded-md file:border-0 file:bg-primary file:px-3 file:py-1 file:text-primary-foreground"
            id={`item-photo-file-${suffix}`}
            onChange={(event) => {
              const selectedFile = event.currentTarget.files?.[0] ?? null;
              releaseFilePreview();
              setFile(null);
              setUploadError("");
              setUploadMessage("");
              if (!selectedFile) return;
              setFile(selectedFile);
              if (!(selectedFile.type in FILE_EXTENSIONS)) {
                setUploadError("Choose a JPEG, PNG, WebP, or AVIF image.");
                return;
              }
              if (selectedFile.size > MAX_FILE_SIZE) {
                setUploadError("Images must be 5 MB or smaller.");
                return;
              }
              const objectUrl = URL.createObjectURL(selectedFile);
              filePreviewRef.current = objectUrl;
              setFilePreview(objectUrl);
            }}
            ref={fileInputRef}
            type="file"
          />
          <p className="text-xs text-muted-foreground">
            JPEG, PNG, WebP, or AVIF. Maximum size: 5 MB.
          </p>
          {file && !uploadError && (
            <p className="break-all text-xs text-muted-foreground">
              Selected: {file.name}
            </p>
          )}
          <div>
            <Button
              disabled={!file || uploading || !!uploadError}
              onClick={uploadSelectedFile}
              type="button"
              variant="outline"
            >
              {uploading ? "Uploading…" : "Upload and use this photo"}
            </Button>
          </div>
          {uploadError && <p className="text-sm text-destructive" role="alert">{uploadError}</p>}
          {uploading && <p className="text-sm text-muted-foreground" role="status">Uploading photo…</p>}
          {uploadMessage && <p className="text-sm text-primary" role="status">{uploadMessage}</p>}
        </div>
      </div>

      <div className="grid content-start gap-2">
        <span className="text-sm font-medium">Photo preview</span>
        <div
          aria-label={`Preview for ${itemName}`}
          className="aspect-[16/10] w-full rounded-xl border border-border bg-muted bg-cover bg-center"
          role="img"
          style={{
            backgroundImage: `linear-gradient(180deg, transparent 70%, rgb(11 20 36 / 16%) 100%), url("${(filePreview ?? preview.src).replace(/["\\\n\r]/g, "%22")}")`,
          }}
        />
        <p className="text-xs text-muted-foreground">
          {file
            ? `Local preview: ${file.name}`
            : photoUrl
              ? `Current photo: ${preview.label}`
              : `Automatic photo: ${preview.label}`}
        </p>
        {preview.credit && preview.creditUrl && !filePreview && (
          <a
            className="text-xs text-muted-foreground underline-offset-4 hover:underline"
            href={preview.creditUrl}
            rel="noreferrer"
            target="_blank"
          >
            Photo credit: {preview.credit}
          </a>
        )}
      </div>
    </div>
  );
}
