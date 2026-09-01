/**
 * CMS Backend - Strapi-compatible Node.js service entrypoint.
 * Exposes /health for k8s liveness/readiness and /metrics for Prometheus.
 */
const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 1337;

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequests = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'],
});
register.registerMetric(httpRequests);

app.use(express.json());
app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequests.inc({ method: req.method, route: req.path, status: res.statusCode });
  });
  next();
});

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'cms-backend' }));
app.get('/ready', (_req, res) => res.json({ ready: true }));
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/api/articles', (_req, res) => {
  res.json({
    data: [
      { id: 1, title: 'Hello from Strapi', body: 'Served from EKS pod.' },
      { id: 2, title: 'Second article', body: 'Media stored in S3.' },
    ],
  });
});

app.listen(PORT, () => console.log(`cms-backend listening on ${PORT}`));
