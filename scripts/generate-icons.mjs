// Generates every RoboRef app icon from a single source of truth.
//
// Design: a centered green gear with a darker-green keyline, a drop shadow,
// and a central square hole that shows the background through it — over a full-bleed
// background of 7 vertical black/white stripes (odd count, so both outer
// stripes are black).
//
// Outputs (all written to public/icons/):
//   - roboref.svg            the canonical vector icon
//   - roboref-<n>x<n>.png    raster icons for the PWA manifest
//   - favicon.ico                multi-resolution favicon (16/32/48) for tabs
//
// Run after changing any constant below:  node scripts/generate-icons.mjs
// (sharp is a dev dependency of the repo; run from anywhere in the project.)

import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import sharp from "sharp";

// Written to public/icons/ (this script lives in scripts/, outside the
// web-served public dir so the deploy/bundler never tries to process it).
const OUT_DIR = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "public",
  "icons",
);

const SIZE = 512;
const STRIPES = 7; // odd → both outer stripes are black
const STRIPE_W = SIZE / STRIPES; // consistent stripe width
const CX = SIZE / 2; // gear centre == image centre
const CY = SIZE / 2;

// ---- Gear geometry -------------------------------------------------------
const TEETH = 12;
const R_TIP = 170; // tooth tip (outer) radius
const R_ROOT = 110; // root radius — gear "body"; R_TIP - R_ROOT = 60px teeth
const BORE_HALF = 46; // central square hole half-side (stays within the white stripe)
const BORE_CORNER = 16; // square hole corner radius (rounded corners)
const P = (Math.PI * 2) / TEETH; // angular period per tooth
const ALPHA = P * 0.3; // root half-angle (tooth base width — thicker base)
const BETA = P * 0.07; // tip half-angle (≈0 → sharp, pointy teeth)

// Gear colours, specified in OKLCH and converted to sRGB hex at build time
// (the SVG renderer used for the raster icons doesn't understand oklch()).
// The keyline is a darker shade of the gear's green, so the silhouette has
// strong contrast against the white stripes while staying on-palette.
const GEAR_COLOR = "oklch(59.6% .145 163.225)"; // emerald green
const KEYLINE_COLOR = "oklch(40% .145 163.225)"; // darker-green outline
const KEYLINE_WIDTH = 10; // outline half-width, in 512px canvas units
const GEAR_OPACITY = 1; // fully opaque

const GEAR_FILL = "#009669";
const KEYLINE_FILL = "#00563a"; 

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

// Central rounded-square hole as a second sub-path; fill-rule="evenodd" punches it out.
const bx0 = CX - BORE_HALF, bx1 = CX + BORE_HALF;
const by0 = CY - BORE_HALF, by1 = CY + BORE_HALF;
const rc = BORE_CORNER;
const bore = `M ${bx0 + rc} ${by0} L ${bx1 - rc} ${by0} A ${rc} ${rc} 0 0 1 ${bx1} ${by0 + rc} L ${bx1} ${by1 - rc} A ${rc} ${rc} 0 0 1 ${bx1 - rc} ${by1} L ${bx0 + rc} ${by1} A ${rc} ${rc} 0 0 1 ${bx0} ${by1 - rc} L ${bx0} ${by0 + rc} A ${rc} ${rc} 0 0 1 ${bx0 + rc} ${by0} Z`;

// ---- Stripes -------------------------------------------------------------
let stripes = "";
for (let i = 0; i < STRIPES; i++) {
  const x = (i * STRIPE_W).toFixed(3);
  const w = STRIPE_W.toFixed(3);
  const fill = i % 2 === 0 ? "#999999" : "#ffffff";
  stripes += `  <rect x="${x}" y="0" width="${w}" height="${SIZE}" fill="${fill}"/>\n`;
}

const svg = `<svg width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="gear-shadow" x="-25%" y="-25%" width="150%" height="150%">
      <feDropShadow dx="0" dy="5" stdDeviation="6" flood-color="#000000" flood-opacity="0.4"/>
    </filter>
  </defs>
${stripes}  <path d="${cog} ${bore}" fill="${KEYLINE_FILL}" stroke="${KEYLINE_FILL}" stroke-width="${2 * KEYLINE_WIDTH}" stroke-linejoin="round" fill-rule="evenodd" filter="url(#gear-shadow)"/>
  <path d="${cog} ${bore}" fill="${GEAR_FILL}" fill-rule="evenodd" fill-opacity="${GEAR_OPACITY}"/>
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
