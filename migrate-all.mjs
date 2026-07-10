// migrate-all.js — Run with: node migrate-all.js
// Migrates all root-level Webflow HTML pages to Astro pages
// Each .astro file: imports BaseLayout, strips <html>/<head>/<body>, keeps body content only

import { readFileSync, writeFileSync, readdirSync, statSync, existsSync, mkdirSync } from 'fs';
import { join, basename, extname } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const WEBFLOW_DIR = join(__dirname, 'youtap-indonesia.webflow');
const PAGES_DIR = join(__dirname, 'src', 'pages');

// Ensure pages dir exists
if (!existsSync(PAGES_DIR)) mkdirSync(PAGES_DIR, { recursive: true });

// Void elements that must be self-closed in Astro/JSX
const VOID_ELEMENTS = ['img', 'input', 'source', 'embed', 'area', 'base', 'col', 'hr', 'br', 'link', 'meta', 'param', 'track', 'wbr'];

function extractMeta(html, attr, name) {
  // Handles both attribute orders
  let m = html.match(new RegExp(`<meta[^>]+name="${name}"[^>]+content="([^"]*)"`, 'i'));
  if (!m) m = html.match(new RegExp(`<meta[^>]+content="([^"]*)"[^>]+name="${name}"`, 'i'));
  return m ? m[1] : '';
}

function convertToAstro(html, slug) {
  // --- Extract title ---
  const titleMatch = html.match(/<title>([\s\S]*?)<\/title>/i);
  const title = (titleMatch ? titleMatch[1].trim() : 'Youtap Indonesia').replace(/"/g, '&quot;');

  // --- Extract description ---
  const description = extractMeta(html, 'content', 'description').replace(/"/g, '&quot;');

  // --- Extract body content ---
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*)<\/body>/i);
  if (!bodyMatch) throw new Error('No <body> tag found');
  let body = bodyMatch[1];

  // --- Fix asset paths (relative → public root) ---
  body = body.replace(/src="images\//g, 'src="/images/');
  body = body.replace(/href="images\//g, 'href="/images/');
  body = body.replace(/srcset="images\//g, 'srcset="/images/');
  // srcset comma-separated entries: ", images/xxx" → ", /images/xxx"
  body = body.replace(/([\s,])images\//g, '$1/images/');
  body = body.replace(/src="js\//g, 'src="/js/');
  body = body.replace(/src="videos\//g, 'src="/videos/');
  body = body.replace(/src="fonts\//g, 'src="/fonts/');
  body = body.replace(/href="css\//g, 'href="/css/');
  body = body.replace(/src="css\//g, 'src="/css/');

  // --- Self-close bare void elements that are not already self-closed ---
  // Pattern: <tag(attrs)> where last char before > is not /
  const voidPattern = new RegExp(
    `<(${VOID_ELEMENTS.join('|')})(\\s[^>]*?)?(?<!\\/)>`,
    'gi'
  );
  body = body.replace(voidPattern, (match, tag, attrs) => {
    return `<${tag}${attrs || ''} />`;
  });
  // Cleanup double-space before />
  body = body.replace(/\s+\/>/g, ' />');

  // --- Add is:inline to <script> tags ---
  body = body.replace(/<script(?! is:inline)(\s|>)/g, '<script is:inline$1');

  return `---
import BaseLayout from '../layouts/BaseLayout.astro';
import Navbar from '../components/Navbar.astro';
import Footer from '../components/Footer.astro';
---

<BaseLayout title="${title}" description="${description}">
${body}
</BaseLayout>
`;
}

// --- Helper for recursive directory walking ---
function getAllHtmlFiles(dirPath, arrayOfFiles = []) {
  const files = readdirSync(dirPath);
  files.forEach((file) => {
    const fullPath = join(dirPath, file);
    if (statSync(fullPath).isDirectory()) {
      arrayOfFiles = getAllHtmlFiles(fullPath, arrayOfFiles);
    } else if (extname(file) === '.html') {
      arrayOfFiles.push(fullPath);
    }
  });
  return arrayOfFiles;
}

const LEGACY_PAGES = new Set([
  'old-home.html', 'old-home-2.html', 'old-about-us.html', 'contact-us-old.html', 'old-blogs.html',
  'blog-copy.html', 'blogs-copy.html', 'blogs-stagging.html', 'romie-copy.html',
  'landing-new.html', 'landing-new-2.html', 'landing-new-3.html', 'landing-new-4.html', 'basic.html',
  'detail_belanja-stok-feature.html', 'detail_belanja-stok-scm-partners.html', 'detail_faq-collection.html',
  'detail_faq.html', 'detail_features.html', 'detail_kebijakan-privasi.html', 'detail_list-dukungan-printer.html',
  'detail_media.html', 'detail_partners.html', 'detail_product.html', 'detail_sku.html', 'detail_tnc.html',
  'detail_tncs-ajak-cuan.html', 'detail_video-tutorial-youtube.html', 'bos/untitled.html', 'page/upgrade-account.html'
].map(p => p.replace(/\//g, '\\')));

// --- Run migration ---
const htmlFiles = getAllHtmlFiles(WEBFLOW_DIR);

const migrated = [];
const skipped = [];
const failed = [];

for (const fullPath of htmlFiles) {
  // Get relative path from WEBFLOW_DIR (e.g., "app/romie.html")
  const relativePath = fullPath.substring(WEBFLOW_DIR.length + 1);
  
  if (LEGACY_PAGES.has(relativePath) || LEGACY_PAGES.has(relativePath.replace(/\\/g, '/'))) {
    skipped.push(`[LEGACY] ${relativePath}`);
    continue;
  }

  const slugPath = relativePath.replace(/\.html$/, '');
  const outputPath = join(PAGES_DIR, `${slugPath}.astro`);
  
  // Ensure nested output directory exists
  const outputDir = dirname(outputPath);
  if (!existsSync(outputDir)) {
    mkdirSync(outputDir, { recursive: true });
  }

  if (existsSync(outputPath)) {
    skipped.push(slugPath);
    continue;
  }

  try {
    const html = readFileSync(fullPath, 'utf-8');
    const astro = convertToAstro(html, slugPath);
    writeFileSync(outputPath, astro, 'utf-8');
    migrated.push(slugPath);
  } catch (err) {
    failed.push(`${slugPath}: ${err.message}`);
  }
}

console.log(`\n=== Migration Report ===`);
console.log(`Migrated : ${migrated.length}`);
console.log(`Skipped  : ${skipped.length}  (already existed)`);
console.log(`Failed   : ${failed.length}`);

if (migrated.length) {
  console.log('\nMigrated pages:');
  migrated.forEach(s => console.log(`  + ${s}`));
}
if (skipped.length) {
  console.log('\nSkipped (already exist):');
  skipped.forEach(s => console.log(`  ~ ${s}`));
}
if (failed.length) {
  console.log('\nFailed:');
  failed.forEach(s => console.log(`  ! ${s}`));
}
