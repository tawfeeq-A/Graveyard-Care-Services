const SUPABASE_URL = "https://oggyndaynrkcwnmxmusp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9nZ3luZGF5bnJrY3dubXhtdXNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1MTM5NzgsImV4cCI6MjA5NzA4OTk3OH0.WkItS_HH21XKHC9eRzWFfIE03RgNj0BhkOD9RxX8a1g";
const DEFAULT_BRAND = "Grave Care Services";
const DEFAULT_TITLE_SUFFIX = "Grave Maintenance in Srinagar";
const DEFAULT_DESCRIPTION = "Respectful grave maintenance in Srinagar. Cleaning, deweeding, alignment, DPC work and custom requests handled with family confirmation.";

function escapeHtml(value = "") {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function replaceOrInsertMeta(html, tagRegex, replacement) {
  if (tagRegex.test(html)) return html.replace(tagRegex, replacement);
  return html.replace("</head>", `  ${replacement}\n</head>`);
}

async function getSiteMeta() {
  try {
    const endpoint = `${SUPABASE_URL}/rest/v1/site_settings?id=eq.main&select=brand_name,hero_title,hero_subtitle,content_json`;
    const response = await fetch(endpoint, {
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        Accept: "application/json"
      }
    });

    if (!response.ok) throw new Error(`Supabase ${response.status}`);
    const rows = await response.json();
    const row = Array.isArray(rows) ? rows[0] : null;
    if (!row) throw new Error("No site_settings row");

    const brand = row.brand_name || DEFAULT_BRAND;
    const copy = row.content_json || {};

    // The preview title follows the current admin Business / Brand name.
    // If you want fully custom preview text, edit SEO title/description in Admin > Website Text.
    let title = `${brand} | ${DEFAULT_TITLE_SUFFIX}`;
    if (copy.seoTitle && copy.seoTitle !== `${DEFAULT_BRAND} | Professional Grave Maintenance in Srinagar`) {
      title = String(copy.seoTitle).replace(DEFAULT_BRAND, brand);
    }

    const description = copy.seoDescription || row.hero_subtitle || DEFAULT_DESCRIPTION;
    return { title, description };
  } catch (error) {
    console.warn("Dynamic OG meta fallback:", error.message || error);
    return {
      title: `${DEFAULT_BRAND} | ${DEFAULT_TITLE_SUFFIX}`,
      description: DEFAULT_DESCRIPTION
    };
  }
}

export default async (request, context) => {
  const url = new URL(request.url);

  // Only HTML page requests need dynamic Open Graph tags.
  const isPageRequest = request.method === "GET" &&
    !url.pathname.includes(".") &&
    !url.pathname.startsWith("/api/");

  const response = await context.next();
  const contentType = response.headers.get("content-type") || "";

  if (!isPageRequest && !contentType.includes("text/html")) return response;
  if (!contentType.includes("text/html")) return response;

  let html = await response.text();
  const { title, description } = await getSiteMeta();
  const safeTitle = escapeHtml(title);
  const safeDescription = escapeHtml(description);
  const safeUrl = escapeHtml(request.url);

  html = html.replace(/<title>[\s\S]*?<\/title>/i, `<title>${safeTitle}</title>`);
  html = replaceOrInsertMeta(html, /<meta\s+name=["']description["'][^>]*>/i, `<meta name="description" content="${safeDescription}" />`);
  html = replaceOrInsertMeta(html, /<meta\s+property=["']og:title["'][^>]*>/i, `<meta property="og:title" content="${safeTitle}" />`);
  html = replaceOrInsertMeta(html, /<meta\s+property=["']og:description["'][^>]*>/i, `<meta property="og:description" content="${safeDescription}" />`);
  html = replaceOrInsertMeta(html, /<meta\s+property=["']og:url["'][^>]*>/i, `<meta property="og:url" content="${safeUrl}" />`);
  html = replaceOrInsertMeta(html, /<meta\s+property=["']og:type["'][^>]*>/i, `<meta property="og:type" content="website" />`);
  html = replaceOrInsertMeta(html, /<meta\s+name=["']twitter:card["'][^>]*>/i, `<meta name="twitter:card" content="summary" />`);
  html = replaceOrInsertMeta(html, /<meta\s+name=["']twitter:title["'][^>]*>/i, `<meta name="twitter:title" content="${safeTitle}" />`);
  html = replaceOrInsertMeta(html, /<meta\s+name=["']twitter:description["'][^>]*>/i, `<meta name="twitter:description" content="${safeDescription}" />`);

  const headers = new Headers(response.headers);
  headers.set("content-type", "text/html; charset=utf-8");
  // Let WhatsApp/social scrapers get fresh admin-panel changes more often.
  headers.set("cache-control", "no-cache, no-store, must-revalidate");

  return new Response(html, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
};
