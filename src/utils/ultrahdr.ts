/**
 * Ultra HDR JPEG Generator (Google / ISO 21496-1 Gain Map spec)
 * Converts a standard QR canvas into an Ultra HDR JPEG Blob URL containing
 * embedded GainMap metadata and MPF payload for hardware HDR decoding on Android & Chrome.
 */
import { encodeGainMap, writeJpegGainMap, type HdrifyImage } from "hdrify";

export function createUltraHDRJpeg(canvas: HTMLCanvasElement): string {
  const width = canvas.width;
  const height = canvas.height;
  
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    // Fallback to standard SDR if we can't get context
    return canvas.toDataURL("image/jpeg", 0.95);
  }
  
  const imgData = ctx.getImageData(0, 0, width, height);
  const data = imgData.data;
  
  // Create a Float32Array for the HDR image data
  const floatData = new Float32Array(width * height * 4);
  
  for (let i = 0; i < data.length; i += 4) {
    // Determine if the pixel is dark (a QR module) or light (background)
    const isDark = data[i] < 128 && data[i + 1] < 128 && data[i + 2] < 128;
    
    if (isDark) {
      // Dark modules stay black
      floatData[i] = 0.0;
      floatData[i + 1] = 0.0;
      floatData[i + 2] = 0.0;
      floatData[i + 3] = 1.0;
    } else {
      // White background is pushed to HDR luminance (e.g. 8x brighter than standard white)
      floatData[i] = 8.0;
      floatData[i + 1] = 8.0;
      floatData[i + 2] = 8.0;
      floatData[i + 3] = 1.0;
    }
  }

  const hdrImage: HdrifyImage = {
    width,
    height,
    data: floatData,
    linearColorSpace: "linear-rec709", // sRGB primaries
  };

  try {
    // Encode the HDR float array into a gain map + SDR base
    const encoding = encodeGainMap(hdrImage);
    
    // Write the Ultra HDR JPEG bytes
    const ultraHdrBytes = writeJpegGainMap(encoding, { quality: 95 });
    
    // Create Blob and return Blob URL
    const blob = new Blob([ultraHdrBytes as any], { type: "image/jpeg" });
    return URL.createObjectURL(blob);
  } catch (err) {
    // Fallback
    return canvas.toDataURL("image/jpeg", 0.95);
  }
}

/**
 * Detects if the current device has an HDR-capable display AND is running a Chromium-based browser
 * that supports Ultra HDR (ISO 21496-1) gain map rendering.
 */
export function isHDRSupported(): boolean {
  if (typeof window === "undefined") return false;

  // 1. Hardware check: Screen must support High Dynamic Range (HDR)
  const hasHDRDisplay = window.matchMedia("(dynamic-range: high)").matches;
  if (!hasHDRDisplay) return false;

  // 2. Exclude iOS / iPadOS (all iOS browsers use WebKit, which lacks client-side libultrahdr GainMap rendering)
  const ua = navigator.userAgent;
  const isIOS = /iPhone|iPad|iPod/i.test(ua) || (navigator.maxTouchPoints > 2 && /Macintosh/i.test(ua));
  if (isIOS) return false;

  // 3. Exclude Firefox
  const isFirefox = /Firefox|FxiOS/i.test(ua);
  if (isFirefox) return false;

  // 4. Exclude native Safari on macOS
  const isSafari = /Safari/i.test(ua) && !/Chrome|Chromium|Edg|OPR|Brave/i.test(ua);
  if (isSafari) return false;

  // 5. Verify Chromium engine
  const isChromium =
    Boolean(
      (navigator as any).userAgentData?.brands?.some((b: any) =>
        /Chromium|Google Chrome|Microsoft Edge|Brave/i.test(b.brand)
      )
    ) || /Chrome|Chromium|Edg|OPR|Brave/i.test(ua);

  return isChromium;
}

