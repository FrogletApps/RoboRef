import { writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import sharp from "../server/node_modules/sharp/lib/index.js";

const ROOT_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const APP_DIR = path.join(ROOT_DIR, "app");

const ASSETS_ICONS_DIR = path.join(APP_DIR, "assets", "icons");
const WEB_ICONS_DIR = path.join(APP_DIR, "web", "icons");
const WEB_DIR = path.join(APP_DIR, "web");
const ANDROID_RES_DIR = path.join(APP_DIR, "android", "app", "src", "main", "res");
const IOS_ICONS_DIR = path.join(APP_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset");

[ASSETS_ICONS_DIR, WEB_ICONS_DIR, WEB_DIR, ANDROID_RES_DIR, IOS_ICONS_DIR].forEach((dir) => {
  mkdirSync(dir, { recursive: true });
});

const SIZE = 512;
const STRIPES = 7;
const STRIPE_W = SIZE / STRIPES;
const CX = SIZE / 2;
const CY = SIZE / 2;

// ---- Gear geometry -------------------------------------------------------
const TEETH = 12;
const R_TIP = 170;
const R_ROOT = 110;
const BORE_HALF = 46;
const BORE_CORNER = 16;
const P = (Math.PI * 2) / TEETH;
const ALPHA = P * 0.3;
const BETA = P * 0.07;

const GEAR_FILL = "#00731f";
const KEYLINE_FILL = "#004613";
const KEYLINE_WIDTH = 10;
const GEAR_OPACITY = 1;

const pt = (r, a) =>
  `${(CX + r * Math.cos(a)).toFixed(3)} ${(CY + r * Math.sin(a)).toFixed(3)}`;

let cog = "";
for (let i = 0; i < TEETH; i++) {
  const c = i * P - Math.PI / 2;
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

const bx0 = CX - BORE_HALF, bx1 = CX + BORE_HALF;
const by0 = CY - BORE_HALF, by1 = CY + BORE_HALF;
const rc = BORE_CORNER;
const bore = `M ${bx0 + rc} ${by0} L ${bx1 - rc} ${by0} A ${rc} ${rc} 0 0 1 ${bx1} ${by0 + rc} L ${bx1} ${by1 - rc} A ${rc} ${rc} 0 0 1 ${bx1 - rc} ${by1} L ${bx0 + rc} ${by1} A ${rc} ${rc} 0 0 1 ${bx0} ${by1 - rc} L ${bx0} ${by0 + rc} A ${rc} ${rc} 0 0 1 ${bx0 + rc} ${by0} Z`;

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

// 1. Write SVGs
writeFileSync(path.join(ASSETS_ICONS_DIR, "roboref.svg"), svg);
writeFileSync(path.join(WEB_DIR, "roboref.svg"), svg);
writeFileSync(path.join(WEB_ICONS_DIR, "roboref.svg"), svg);
console.log("Wrote roboref.svg to assets and web");

// 2. PNG Renderer
const svgBuf = Buffer.from(svg);
const renderPng = (px) =>
  sharp(svgBuf, { density: 384 })
    .resize(px, px, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

// 3. Render Flutter Assets
const ASSET_SIZES = [48, 72, 96, 144, 168, 192, 256, 512, 1024];
for (const px of ASSET_SIZES) {
  writeFileSync(
    path.join(ASSETS_ICONS_DIR, `roboref-${px}x${px}.png`),
    await renderPng(px),
  );
}
console.log("Wrote Flutter asset PNGs");

// 4. Render Web PWA Icons
writeFileSync(path.join(WEB_ICONS_DIR, "Icon-192.png"), await renderPng(192));
writeFileSync(path.join(WEB_ICONS_DIR, "Icon-512.png"), await renderPng(512));
writeFileSync(path.join(WEB_ICONS_DIR, "Icon-maskable-192.png"), await renderPng(192));
writeFileSync(path.join(WEB_ICONS_DIR, "Icon-maskable-512.png"), await renderPng(512));
writeFileSync(path.join(WEB_DIR, "favicon.png"), await renderPng(64));
console.log("Wrote Web PWA icons & favicon.png");

// 5. Generate favicon.ico (16, 32, 48)
const ICO_SIZES = [16, 32, 48];
const pngs = await Promise.all(ICO_SIZES.map(renderPng));
const header = Buffer.alloc(6);
header.writeUInt16LE(0, 0);
header.writeUInt16LE(1, 2);
header.writeUInt16LE(pngs.length, 4);
const dir = Buffer.alloc(16 * pngs.length);
let offset = 6 + 16 * pngs.length;
pngs.forEach((png, i) => {
  const sz = ICO_SIZES[i];
  const e = 16 * i;
  dir.writeUInt8(sz, e);
  dir.writeUInt8(sz, e + 1);
  dir.writeUInt16LE(1, e + 4);
  dir.writeUInt16LE(32, e + 6);
  dir.writeUInt32LE(png.length, e + 8);
  dir.writeUInt32LE(offset, e + 12);
  offset += png.length;
});
const icoBuffer = Buffer.concat([header, dir, ...pngs]);
writeFileSync(path.join(ASSETS_ICONS_DIR, "favicon.ico"), icoBuffer);
writeFileSync(path.join(WEB_DIR, "favicon.ico"), icoBuffer);
console.log("Wrote favicon.ico");

// 6. Generate Android Mipmap Icons
const ANDROID_MIPMAPS = [
  { folder: "mipmap-mdpi", size: 48 },
  { folder: "mipmap-hdpi", size: 72 },
  { folder: "mipmap-xhdpi", size: 96 },
  { folder: "mipmap-xxhdpi", size: 144 },
  { folder: "mipmap-xxxhdpi", size: 192 },
];
for (const { folder, size } of ANDROID_MIPMAPS) {
  const targetDir = path.join(ANDROID_RES_DIR, folder);
  mkdirSync(targetDir, { recursive: true });
  writeFileSync(path.join(targetDir, "ic_launcher.png"), await renderPng(size));
}
console.log("Wrote Android mipmap icons");

// 7. Generate iOS AppIcon Set
const IOS_ICONS = [
  { name: "Icon-App-20x20@1x.png", size: 20 },
  { name: "Icon-App-20x20@2x.png", size: 40 },
  { name: "Icon-App-20x20@3x.png", size: 60 },
  { name: "Icon-App-29x29@1x.png", size: 29 },
  { name: "Icon-App-29x29@2x.png", size: 58 },
  { name: "Icon-App-29x29@3x.png", size: 87 },
  { name: "Icon-App-40x40@1x.png", size: 40 },
  { name: "Icon-App-40x40@2x.png", size: 80 },
  { name: "Icon-App-40x40@3x.png", size: 120 },
  { name: "Icon-App-60x60@2x.png", size: 120 },
  { name: "Icon-App-60x60@3x.png", size: 180 },
  { name: "Icon-App-76x76@1x.png", size: 76 },
  { name: "Icon-App-76x76@2x.png", size: 152 },
  { name: "Icon-App-83.5x83.5@2x.png", size: 167 },
  { name: "Icon-App-1024x1024@1x.png", size: 1024 },
];
for (const { name, size } of IOS_ICONS) {
  writeFileSync(path.join(IOS_ICONS_DIR, name), await renderPng(size));
}
console.log("Wrote iOS AppIcon set");

console.log("All RoboRef icons successfully generated!");
