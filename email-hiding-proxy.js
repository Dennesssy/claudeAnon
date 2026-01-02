#!/usr/bin/env node
/**
 * Email Hiding Proxy for Claude Code
 *
 * Intercepts Anthropic API calls and removes email from /v1/account response
 * All other requests pass through unchanged.
 *
 * Usage: Called by claudeanon script
 * Port: 3738 (configurable via PORT env var)
 */

const http = require('http');
const https = require('https');

const UPSTREAM_URL = process.env.UPSTREAM_URL || 'https://api.anthropic.com';
const UPSTREAM_API_KEY = process.env.UPSTREAM_API_KEY;
const PORT = process.env.PORT || 3738;

const upstreamUrl = new URL(UPSTREAM_URL);

const server = http.createServer((clientReq, clientRes) => {
  const options = {
    hostname: upstreamUrl.hostname,
    port: upstreamUrl.port || 443,
    path: clientReq.url,
    method: clientReq.method,
    headers: {
      ...clientReq.headers,
      host: upstreamUrl.host,
    },
  };

  // Add API key if present
  if (UPSTREAM_API_KEY) {
    options.headers['x-api-key'] = UPSTREAM_API_KEY;
    options.headers['anthropic-version'] = '2023-06-01';
  }

  const upstreamReq = https.request(options, (upstreamRes) => {
    let body = '';

    upstreamRes.on('data', (chunk) => {
      body += chunk.toString();
    });

    upstreamRes.on('end', () => {
      // Strip email from /v1/account responses
      if (clientReq.url === '/v1/account' || clientReq.url === '/v1/account?') {
        try {
          const data = JSON.parse(body);
          delete data.email;
          delete data.name;
          body = JSON.stringify(data);
        } catch (e) {
          // If parsing fails, return empty response
          body = JSON.stringify({});
        }
      }

      clientRes.writeHead(upstreamRes.statusCode, upstreamRes.headers);
      clientRes.end(body);
    });
  });

  upstreamReq.on('error', (err) => {
    console.error('Proxy error:', err.message);
    clientRes.writeHead(502);
    clientRes.end('Bad Gateway');
  });

  // Forward client body to upstream
  clientReq.pipe(upstreamReq);
});

server.listen(PORT, () => {
  console.error(`Email-hiding proxy running on port ${PORT}`);
  console.error(`Forwarding to: ${UPSTREAM_URL}`);
});
