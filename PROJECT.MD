# PROJECT.md

## Project Overview
Migration project from Webflow export to Astro 5.

Website: Youtap Indonesia  
Type: Company Profile / Product Information  
Current Source: Exported Webflow HTML/CSS/JS  
Target Stack:
- Astro 5
- Tailwind CSS (optional, hybrid with legacy CSS)
- Vanilla JavaScript / GSAP for animations
- Vercel deployment

---

## Goals
1. Migrate all pages from Webflow to Astro
2. Preserve visual layout 1:1
3. Improve code quality and maintainability
4. Optimize performance and SEO
5. Reuse shared layout components

---

## Coding Rules
- Use semantic HTML
- Avoid unnecessary div nesting
- Split reusable sections into components
- Keep CSS modular
- Prefer Astro components over duplicated HTML
- Preserve existing class names if migration is faster

---

## Folder Structure
src/
  components/
  layouts/
  pages/
  styles/
  scripts/

public/
  images/
  fonts/
  js/

---

## Components To Extract
- Navbar
- Footer
- Head Metadata
- Shared CTA sections
- FAQ Accordion
- Blog Cards

---

## Page Migration Rules
- Remove .html extension
- Preserve existing URLs
- Convert repeated sections into components
- Static assets go to /public

Examples:
about.html -> src/pages/about.astro
app/index.html -> src/pages/app/index.astro

---

## Antigravity Instructions
When editing code:
- Never rewrite the entire project unless requested
- Modify only relevant files
- Keep changes minimal and precise
- Explain architectural decisions before large refactors

## AI Working Rules

When working on this codebase:

1. Never refactor unrelated files
2. Never rename existing CSS classes unless asked
3. Preserve Webflow HTML structure during initial migration
4. Make incremental changes only
5. One task at a time
6. Explain changes before major modifications
7. Prioritize working code over perfect architecture