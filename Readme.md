# 🚀 SLO Testing Application

Enterprise-grade Node.js application for testing Service Level Objectives (SLOs) and Service Level Indicators (SLIs) with **Datadog**, **New Relic**, and **Atatus** APM tools.

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [SLO Configuration Examples](#slo-configuration-examples)
- [Load Testing](#load-testing)
- [Troubleshooting](#troubleshooting)

## ✨ Features

- **Multiple APM Support**: Datadog APM, New Relic, Atatus
- **SLO Testing Routes**: Success, error, timeout, and external call scenarios
- **Health Monitoring**: Built-in `/health` and `/ready` endpoints
- **Distributed Tracing**: Custom spans and tags for Datadog
- **Request Metrics**: Counter-based incoming/outgoing request tracking
- **Enterprise Ready**: Proper error handling, logging, and graceful shutdowns

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn
- Datadog Agent (optional, for APM)
- New Relic Agent (optional)

### Installation

```bash
# Clone and install
git clone <repo-url>
cd node-slo
npm install

# Configure environment
cp .env.example .env  # Edit with your APM credentials

# Start the application
npm start
```

The application will be available at `http://localhost:3000`

## 🔧 Environment Variables

Create a `.env` file with your configuration:

```env
# ============================================
# Datadog APM Configuration
# ============================================
DD_SERVICE=Node_SLO
DD_ENV=dev
DD_VERSION=1.0.0
DD_TRACE_SAMPLE_RATE=1
DD_TRACE_AGENT_HOSTNAME=localhost
DD_TRACE_AGENT_PORT=8126

# ============================================
# New Relic Configuration
# ============================================
NEW_RELIC_LICENSE_KEY=your_license_key_here
NEW_RELIC_APP_NAME=Node_SLO

# ============================================
# Atatus Configuration
# ============================================
ATATUS_APP_NAME=Node_SLO
ATATUS_LICENSE_KEY=your_license_key_here

# ============================================
# Application Settings
# ============================================
PORT=3000
NODE_ENV=production
```

## 📡 API Endpoints

### Success Routes

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/success/200` | GET | Returns 200 OK with JSON |
| `/success/accepted` | GET | Returns 202 Accepted |
| `/success/delete` | GET | Returns 200 DELETE success |
| `/success/post` | POST | Returns 201 Created |
| `/success/update` | PUT | Returns 200 OK |

### Error Routes

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/error/unhandled` | GET | Throws unhandled exception |
| `/error/handled` | GET | Returns 500 error (handled) |
| `/error/async` | GET | Async Promise rejection |
| `/error/custom-span` | GET | Custom Datadog span error |
| `/error/deleteFail` | GET | Returns 500 DELETE error |
| `/error/updateFail` | GET | Returns 500 PUT error |
| `/error/json` | POST | JSON parse error simulation |

### External & Slow Routes

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/outgoing/httpbin` | GET | External HTTP call to httpbin.org |
| `/outgoing/httpbin?fail=true` | GET | Simulated external failure |
| `/slow/timeout` | GET | 2-minute timeout delay |

### Monitoring Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Liveness probe - returns 200 when healthy |
| `/ready` | GET | Readiness probe - checks memory and status |
| `/metrics` | GET | Request counters (incoming/outgoing) |

## 📊 SLO Configuration Examples

### Datadog SLO

**Error Rate SLO (99.9% availability)**
```json
{
  "name": "Node SLO - Error Rate",
  "description": "99.9% of requests should succeed",
  "type": "metric",
  "query": {
    "numerator": "sum:trace.http.request.errors{service:Node_SLO}.as_rate()",
    "denominator": "sum:trace.http.request.hits{service:Node_SLO}.as_rate()"
  },
  "thresholds": [
    {
      "timeframe": "7d",
      "target": 99.9,
      "warning": 99.95
    }
  ]
}
```

**Latency SLO (p95 < 500ms)**
```json
{
  "name": "Node SLO - Latency",
  "description": "95% of requests under 500ms",
  "type": "monitor",
  "monitor_ids": [12345678],
  "thresholds": [
    {
      "timeframe": "7d",
      "target": 95,
      "warning": 98
    }
  ]
}
```

### New Relic SLO

**Error Rate SLO**
```sql
-- Error rate query
SELECT percentage(count(*), WHERE error IS true)
FROM Transaction
WHERE appName = 'Node_SLO'
SINCE 7 DAYS AGO
```

**Latency SLO**
```sql
-- p95 latency query
SELECT percentile(duration, 95)
FROM Transaction
WHERE appName = 'Node_SLO'
SINCE 7 DAYS AGO
```

### Atatus SLO

Configure SLOs in Atatus dashboard:

1. **Apdex Score**: Set T=500ms for satisfactory response time
2. **Error Rate**: Alert when > 0.1% over 5 minutes
3. **Throughput**: Monitor requests per minute

## 🧪 Load Testing

### Using the Simulator Script

```bash
# Test all endpoints
./simulator.sh test

# Generate load (100 requests, 10 concurrent)
./simulator.sh load

# Full test suite
./simulator.sh full
```

### Using curl

```bash
# Health check
curl http://localhost:3000/health

# Success request
curl http://localhost:3000/success/200

# Error simulation
curl http://localhost:3000/error/handled

# External call
curl http://localhost:3000/outgoing/httpbin

# POST with JSON
curl -X POST -H "Content-Type: application/json" \
  -d '{"test":"data"}' \
  http://localhost:3000/success/post

# Invalid JSON (triggers parse error)
curl -X POST -H "Content-Type: application/json" \
  -d 'invalid json' \
  http://localhost:3000/error/json
```

### Using Apache Bench (ab)

```bash
# Install ab
sudo apt-get install apache2-utils

# Run load test
ab -n 1000 -c 10 http://localhost:3000/success/200
```

### Using hey (recommended)

```bash
# Install hey
go install github.com/rakyll/hey@latest

# Run load test
hey -n 1000 -c 50 -m GET http://localhost:3000/success/200

# POST load test
hey -n 1000 -c 50 -m POST \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}' \
  http://localhost:3000/success/post
```

## 🔍 Troubleshooting

### dd-trace not found

```bash
npm install dd-trace
```

### Datadog Agent not receiving traces

1. Verify agent is running: `sudo systemctl status datadog-agent`
2. Check agent config: `cat /etc/datadog-agent/datadog.yaml`
3. Verify APM is enabled in agent config

### New Relic not reporting

1. Check license key is valid
2. Verify app name in New Relic dashboard
3. Check logs: `cat logs/newrelic_agent.log`

### Port already in use

```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
PORT=3001 npm start
```

## 📁 Project Structure

```
node-slo/
├── app.js                      # Main application entry
├── package.json
├── .env                        # Environment variables
├── simulator.sh                # Load testing script
├── routes/
│   ├── success/               # Success response handlers
│   │   ├── index.js
│   │   ├── get-200.js
│   │   ├── post-201.js
│   │   ├── put-200.js
│   │   ├── delete.js
│   │   ├── accepted202.js
│   │   └── outgoingExample.js
│   ├── errors/                # Error response handlers
│   │   ├── index.js
│   │   ├── handledError.js
│   │   ├── unhandledError.js
│   │   ├── asyncError.js
│   │   ├── customSpanError.js
│   │   ├── deleteFail.js
│   │   └── updateFail.js
│   ├── external/              # External API calls
│   │   ├── index.js
│   │   └── external-call.js
│   └── slow/                  # Timeout/delay handlers
│       └── timeout.js
└── utils/
    ├── counter.js             # Request counters
    └── eventLogger.js         # Event emitter for logging
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## 📄 License

ISC

## 🆘 Support

For issues and questions:
- Datadog: https://docs.datadoghq.com/tracing/
- New Relic: https://docs.newrelic.com/
- Atatus: https://www.atatus.com/docs
