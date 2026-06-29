const request = require('supertest');
const app = require('../src/index');

describe('API Health Checks', () => {
  test('GET / returns service info', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('service', 'secure-gitops-platform');
    expect(res.body).toHaveProperty('status', 'running');
  });

  test('GET /health returns healthy', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('status', 'healthy');
  });

  test('GET /ready returns ready', async () => {
    const res = await request(app).get('/ready');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('status', 'ready');
  });

  test('GET /metrics returns prometheus format', async () => {
    const res = await request(app).get('/metrics');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('http_requests_total');
  });
});
