const ALLOWED_HOSTS = ['instagram.com', 'facebook.com', 'fb.watch'];

function json(statusCode, body) {
  return {
    statusCode,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'public, max-age=3600'
    },
    body: JSON.stringify(body)
  };
}

function allowedUrl(rawUrl) {
  try {
    const parsed = new URL(rawUrl);
    const host = parsed.hostname.toLowerCase();
    if (!['http:', 'https:'].includes(parsed.protocol)) return null;
    if (!ALLOWED_HOSTS.some(allowed => host === allowed || host.endsWith('.' + allowed))) return null;
    return parsed;
  } catch (_) {
    return null;
  }
}

function pickMeta(html, property) {
  const patterns = [
    new RegExp(`<meta[^>]+property=["']${property}["'][^>]+content=["']([^"']+)["'][^>]*>`, 'i'),
    new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${property}["'][^>]*>`, 'i'),
    new RegExp(`<meta[^>]+name=["']${property}["'][^>]+content=["']([^"']+)["'][^>]*>`, 'i'),
    new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+name=["']${property}["'][^>]*>`, 'i')
  ];
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match && match[1]) return decodeHtml(match[1]);
  }
  return '';
}

function decodeHtml(value) {
  return String(value)
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

exports.handler = async (event) => {
  const rawUrl = event.queryStringParameters && event.queryStringParameters.url;
  const parsed = allowedUrl(rawUrl || '');
  if (!parsed) return json(400, { error: 'Only Instagram and Facebook links are supported.' });

  try {
    const response = await fetch(parsed.href, {
      headers: {
        'user-agent': 'Mozilla/5.0 (compatible; GraveCarePreviewBot/1.0; +https://netlify.com)',
        'accept': 'text/html,application/xhtml+xml'
      }
    });
    if (!response.ok) return json(200, { image: '', title: '', description: '', warning: `Preview fetch returned ${response.status}` });

    const html = await response.text();
    let image = pickMeta(html, 'og:image') || pickMeta(html, 'twitter:image');
    const title = pickMeta(html, 'og:title') || pickMeta(html, 'twitter:title');
    const description = pickMeta(html, 'og:description') || pickMeta(html, 'twitter:description');

    if (image) {
      try { image = new URL(image, parsed.href).href; } catch (_) {}
    }

    return json(200, { image, title, description });
  } catch (error) {
    return json(200, { image: '', title: '', description: '', warning: error.message || 'Could not fetch preview.' });
  }
};
