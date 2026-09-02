/**
 * Converts basic Markdown to sanitized, responsive HTML for the public /privacy endpoint.
 */
export function renderPrivacyHtml(markdown: string): string {
  // Simple, safe Markdown to HTML parser
  const lines = markdown.split("\n");
  const htmlBlocks: string[] = [];
  let inList = false;

  const escapeHtml = (str: string) =>
    str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");

  const formatInline = (text: string) => {
    let formatted = escapeHtml(text);
    // Bold: **text**
    formatted = formatted.replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>");
    // Italic: *text*
    formatted = formatted.replace(/\*(.*?)\*/g, "<em>$1</em>");
    // Links: [text](url)
    formatted = formatted.replace(
      /\[(.*?)\]\((https?:\/\/[^\s)]+)\)/g,
      '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
    );
    // Email links: [text](mailto:email) or email text
    formatted = formatted.replace(
      /\[(.*?)\]\(mailto:([^\s)]+)\)/g,
      '<a href="mailto:$2">$1</a>'
    );
    return formatted;
  };

  for (let i = 0; i < lines.length; i++) {
    const rawLine = lines[i];
    const trimmed = rawLine.trim();

    if (!trimmed) {
      if (inList) {
        htmlBlocks.push("</ul>");
        inList = false;
      }
      continue;
    }

    // Horizontal Rule
    if (trimmed === "---" || trimmed === "***" || trimmed === "___") {
      if (inList) {
        htmlBlocks.push("</ul>");
        inList = false;
      }
      htmlBlocks.push("<hr />");
      continue;
    }

    // Headings
    if (trimmed.startsWith("# ")) {
      if (inList) {
        htmlBlocks.push("</ul>");
        inList = false;
      }
      htmlBlocks.push(`<h1>${formatInline(trimmed.slice(2))}</h1>`);
      continue;
    }
    if (trimmed.startsWith("## ")) {
      if (inList) {
        htmlBlocks.push("</ul>");
        inList = false;
      }
      htmlBlocks.push(`<h2>${formatInline(trimmed.slice(3))}</h2>`);
      continue;
    }
    if (trimmed.startsWith("### ")) {
      if (inList) {
        htmlBlocks.push("</ul>");
        inList = false;
      }
      htmlBlocks.push(`<h3>${formatInline(trimmed.slice(4))}</h3>`);
      continue;
    }

    // Bullet Lists
    if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
      if (!inList) {
        htmlBlocks.push("<ul>");
        inList = true;
      }
      htmlBlocks.push(`<li>${formatInline(trimmed.slice(2))}</li>`);
      continue;
    }

    // Regular paragraph
    if (inList) {
      htmlBlocks.push("</ul>");
      inList = false;
    }
    htmlBlocks.push(`<p>${formatInline(trimmed)}</p>`);
  }

  if (inList) {
    htmlBlocks.push("</ul>");
  }

  const contentHtml = htmlBlocks.join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RoboRef Privacy Policy</title>
  <link rel="icon" type="image/png" href="/favicon.png">
  <meta name="description" content="Privacy Policy for RoboRef - Offline-first match anomaly log and referee assistant.">
  <style>
    :root {
      --bg: #f8fafc;
      --card-bg: #ffffff;
      --text: #0f172a;
      --muted: #475569;
      --border: #e2e8f0;
      --primary: #2563eb;
      --primary-hover: #1d4ed8;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0f172a;
        --card-bg: #1e293b;
        --text: #f8fafc;
        --muted: #94a3b8;
        --border: #334155;
        --primary: #3b82f6;
        --primary-hover: #60a5fa;
      }
    }
    * {
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.65;
      margin: 0;
      padding: 32px 16px;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 36px 32px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05);
    }
    @media (max-width: 640px) {
      body { padding: 16px 8px; }
      .container { padding: 24px 16px; border-radius: 12px; }
    }
    .header-nav {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border);
    }
    .back-btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: var(--primary);
      text-decoration: none;
      font-weight: 600;
      font-size: 0.95rem;
    }
    .back-btn:hover {
      color: var(--primary-hover);
      text-decoration: underline;
    }
    .app-badge {
      font-size: 0.85rem;
      color: var(--muted);
      font-weight: 500;
    }
    h1 {
      font-size: 2rem;
      font-weight: 800;
      margin: 0 0 8px 0;
      color: var(--text);
    }
    h2 {
      font-size: 1.3rem;
      font-weight: 700;
      margin-top: 32px;
      margin-bottom: 12px;
      padding-bottom: 6px;
      border-bottom: 1px solid var(--border);
      color: var(--text);
    }
    h3 {
      font-size: 1.1rem;
      font-weight: 600;
      margin-top: 20px;
      margin-bottom: 8px;
      color: var(--text);
    }
    p {
      margin: 12px 0;
      color: var(--muted);
      font-size: 1rem;
    }
    ul {
      margin: 12px 0 16px 20px;
      padding-left: 12px;
    }
    li {
      margin-bottom: 8px;
      color: var(--muted);
      font-size: 0.975rem;
    }
    strong {
      color: var(--text);
      font-weight: 600;
    }
    hr {
      border: 0;
      border-top: 1px solid var(--border);
      margin: 28px 0;
    }
    a {
      color: var(--primary);
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
    footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid var(--border);
      text-align: center;
      font-size: 0.875rem;
      color: var(--muted);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header-nav">
      <a href="/" class="back-btn">&#8592; Go to RoboRef</a>
      <span class="app-badge">RoboRef Assistant</span>
    </div>
    ${contentHtml}
    <footer>
      &copy; ${new Date().getFullYear()} RoboRef. All rights reserved. &bull; <a href="/">roboref.app</a>
    </footer>
  </div>
</body>
</html>`;
}
