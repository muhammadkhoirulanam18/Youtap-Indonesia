import fs from 'fs';

const inputFile = './youtap-indonesia.webflow/spektacuan.html';
const outputFile = './src/pages/spektacuan.astro';

let content = fs.readFileSync(inputFile, 'utf-8');

// Replace relative paths with absolute paths from public root
content = content.replace(/href="css\//g, 'href="/css/');
content = content.replace(/src="images\//g, 'src="/images/');
content = content.replace(/href="images\//g, 'href="/images/');
content = content.replace(/srcset="images\//g, 'srcset="/images/');
content = content.replace(/src="js\//g, 'src="/js/');
content = content.replace(/src="videos\//g, 'src="/videos/');
// Also handle srcset with commas
content = content.replace(/, images\//g, ', /images/');
content = content.replace(/,images\//g, ',/images/');

// Extract title and description
const titleMatch = content.match(/<title>(.*?)<\/title>/);
const title = titleMatch ? titleMatch[1] : 'Youtap Indonesia';

const descMatch = content.match(/<meta content="(.*?)" name="description">/);
const description = descMatch ? descMatch[1] : '';

// Extract everything between <head> and </head> (excluding charset, title, description, and viewport which are in BaseLayout)
let headContent = content.match(/<head>([\s\S]*?)<\/head>/)[1];

// Remove tags that BaseLayout already provides
headContent = headContent.replace(/<meta charset="[^"]*">\n?/, '');
headContent = headContent.replace(/<title>.*?<\/title>\n?/, '');
headContent = headContent.replace(/<meta content=".*?" name="description">\n?/, '');
headContent = headContent.replace(/<meta content="width=device-width, initial-scale=1" name="viewport">\n?/, '');

// Fix script tags with unescaped ampersands or wrap them carefully if needed in Astro, though usually fine in slot="head"
// However, Astro might complain about unclosed tags in HTML if they are not valid, but webflow usually exports standard HTML.

// Extract everything between <body> and </body>
const bodyContent = content.match(/<body[^>]*>([\s\S]*?)<\/body>/)[1];

const astroContent = `---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout title="${title}" description="${description}">
  <Fragment slot="head">
${headContent}  </Fragment>

${bodyContent}
</BaseLayout>
`;

fs.writeFileSync(outputFile, astroContent);
console.log('Successfully created ' + outputFile);
