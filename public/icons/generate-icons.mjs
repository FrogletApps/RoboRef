// Generates every RoboRef app icon from a single source of truth.
//
// Design: a centered green gear (with a drop shadow and a central bore
// that shows the background through it) over a full-bleed background of 7
// vertical black/white stripes — odd count, so both outer stripes are black.
//
// Outputs (all written next to this script, in public/icons/):
//   - roboref.svg            the canonical vector icon
//   - roboref-<n>x<n>.png    raster icons for the PWA manifest
//   - favicon.ico                multi-resolution favicon (16/32/48) for tabs
//
// Run after changing any constant below:  node public/icons/generate-icons.mjs
// (sharp is a dev dependency of the repo; run from anywhere in the project.)

import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import sharp from "sharp";

const OUT_DIR = path.dirname(fileURLToPath(import.meta.url));

const SIZE = 512;
const STRIPES = 7; // odd → both outer stripes are black
const STRIPE_W = SIZE / STRIPES; // consistent stripe width
const CX = SIZE / 2; // gear centre == image centre
const CY = SIZE / 2;

// ---- Gear geometry -------------------------------------------------------
const TEETH = 8;
const R_TIP = 200; // tooth tip (outer) radius
const R_ROOT = 162; // root radius between teeth
const R_BORE = 72; // central bore (hole) radius
const P = (Math.PI * 2) / TEETH; // angular period per tooth
const ALPHA = P * 0.3; // root half-angle
const BETA = P * 0.16; // tip half-angle

// Gear colour, specified in OKLCH and converted to an sRGB hex at build time
// (the SVG renderer used for the raster icons doesn't understand oklch()).
const GEAR_COLOR = "oklch(59.6% .145 163.225)";
const GEAR_OPACITY = 1; // fully opaque

function parseOklch(str) {
  const m = str.match(/oklch\(\s*([\d.]+)%\s+([\d.]+)\s+([\d.]+)/i);
  if (!m) throw new Error(`unsupported colour: ${str}`);
  return { L: parseFloat(m[1]) / 100, C: parseFloat(m[2]), H: parseFloat(m[3]) };
}

function oklchToLinearSrgb(L, C, H) {
  const hr = (H * Math.PI) / 180;
  const a = C * Math.cos(hr);
  const b = C * Math.sin(hr);
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
  return [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  ];
}

// OKLCH → sRGB hex, reducing chroma to fit the sRGB gamut (CSS-style mapping).
function oklchToHex({ L, C, H }) {
  const inGamut = (rgb, eps = 1e-4) =>
    rgb.every((v) => v >= -eps && v <= 1 + eps);
  let chroma = C;
  if (!inGamut(oklchToLinearSrgb(L, C, H))) {
    let lo = 0;
    let hi = C;
    for (let i = 0; i < 40; i++) {
      const mid = (lo + hi) / 2;
      if (inGamut(oklchToLinearSrgb(L, mid, H))) lo = mid;
      else hi = mid;
    }
    chroma = lo;
  }
  const gamma = (x) => {
    const c = Math.min(1, Math.max(0, x));
    return c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055;
  };
  return (
    "#" +
    oklchToLinearSrgb(L, chroma, H)
      .map((v) =>
        Math.round(gamma(v) * 255)
          .toString(16)
          .padStart(2, "0"),
      )
      .join("")
  );
}

const GEAR_FILL = oklchToHex(parseOklch(GEAR_COLOR)); // #009669

const pt = (r, a) =>
  `${(CX + r * Math.cos(a)).toFixed(3)} ${(CY + r * Math.sin(a)).toFixed(3)}`;

// Cog outline: four corners per tooth (root → tip → tip → root).
let cog = "";
for (let i = 0; i < TEETH; i++) {
  const c = i * P - Math.PI / 2; // first tooth centred at top
  const corners = [
    [R_ROOT, c - ALPHA],
    [R_TIP, c - BETA],
    [R_TIP, c + BETA],
    [R_ROOT, c + ALPHA],
  ];
  corners.forEach(([r, a], k) => {
    cog += (i === 0 && k === 0 ? "M" : "L") + pt(r, a) + " ";
  });
}
cog += "Z";

// Central bore as a second sub-path; fill-rule="evenodd" punches it as a hole.
const bore = `M ${CX - R_BORE} ${CY} A ${R_BORE} ${R_BORE} 0 1 0 ${CX + R_BORE} ${CY} A ${R_BORE} ${R_BORE} 0 1 0 ${CX - R_BORE} ${CY} Z`;

// ---- Stripes -------------------------------------------------------------
let stripes = "";
for (let i = 0; i < STRIPES; i++) {
  const x = (i * STRIPE_W).toFixed(3);
  const w = STRIPE_W.toFixed(3);
  const fill = i % 2 === 0 ? "#000000" : "#ffffff";
  stripes += `  <rect x="${x}" y="0" width="${w}" height="${SIZE}" fill="${fill}"/>\n`;
}

const svg = `<svg width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="gear-shadow" x="-25%" y="-25%" width="150%" height="150%">
      <feDropShadow dx="0" dy="5" stdDeviation="6" flood-color="#000000" flood-opacity="0.4"/>
    </filter>
  </defs>
${stripes}  <path d="${cog} ${bore}" fill="${GEAR_FILL}" fill-rule="evenodd" fill-opacity="${GEAR_OPACITY}" filter="url(#gear-shadow)"/>
</svg>
`;

writeFileSync(path.join(OUT_DIR, "roboref.svg"), svg);
console.log("wrote roboref.svg");

// ---- Raster icons --------------------------------------------------------
const svgBuf = Buffer.from(svg);
const renderPng = (px) =>
  sharp(svgBuf, { density: 384 })
    .resize(px, px, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

const PNG_SIZES = [48, 72, 96, 144, 168, 192, 256, 512];
for (const px of PNG_SIZES) {
  writeFileSync(
    path.join(OUT_DIR, `roboref-${px}x${px}.png`),
    await renderPng(px),
  );
}
console.log(`wrote ${PNG_SIZES.length} PNGs`);

// ---- favicon.ico (PNG-encoded 16/32/48 entries) --------------------------
const ICO_SIZES = [16, 32, 48];
const pngs = await Promise.all(ICO_SIZES.map(renderPng));
const header = Buffer.alloc(6);
header.writeUInt16LE(0, 0); // reserved
header.writeUInt16LE(1, 2); // type = icon
header.writeUInt16LE(pngs.length, 4);
const dir = Buffer.alloc(16 * pngs.length);
let offset = 6 + 16 * pngs.length;
pngs.forEach((png, i) => {
  const sz = ICO_SIZES[i];
  const e = 16 * i;
  dir.writeUInt8(sz, e); // width
  dir.writeUInt8(sz, e + 1); // height
  dir.writeUInt16LE(1, e + 4); // colour planes
  dir.writeUInt16LE(32, e + 6); // bits per pixel
  dir.writeUInt32LE(png.length, e + 8); // size
  dir.writeUInt32LE(offset, e + 12); // offset
  offset += png.length;
});
writeFileSync(
  path.join(OUT_DIR, "favicon.ico"),
  Buffer.concat([header, dir, ...pngs]),
);
console.log("wrote favicon.ico");
