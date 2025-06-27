# 📊 Node.js APM Error Simulation with Datadog (`dd-trace`)

This project demonstrates different types of success and error scenarios using `Express` and `dd-trace` for Datadog APM integration. It’s useful for testing how Datadog handles various HTTP responses and application-level errors.

---

## 🛠 Setup

### 1. Clone the Repo

```bash
git clone git@github.com:jayasurya12/node-slo.git
cd node-slo

Install Dependencies:
    npm install

Set Environment Variables:
    Create a .env file:
    cp .env.example .env

Start the Application:
    npm start

🧪 Available Endpoints:
    ✅ Success Endpoints
        Endpoint    Method  Description
        /success/200    GET 200 OK - Standard success
        /success/201    GET 201 Created - New resource created
        /success/202    GET 202 Accepted - Request received, not yet done
        /success/outgoing   GET Sends an outgoing HTTP request to test tracing

    ❌ Error Endpoints
        Endpoint    Method  Description
        /error/unhandled    GET Throws an unhandled server error
        /error/handled  GET Returns a 500 error (handled gracefully)
        /error/async    GET Fails an async function
        /error/custom-span  GET Triggers a custom span with error tags
        /error/json POST    Fails on invalid JSON request body


curl -X POST http://localhost:3000/error/json \
  -H "Content-Type: application/json" \
  -d '{"bad": }'

./simulator.sh                               # Default simulation
./simulator.sh success 90                    # 90% success rate
./simulator.sh success 90 error 10           # 90% success, 10 requests per round
./simulator.sh success 90 error 10 waitevent 2 round 20
./simulator.sh success 90 error 10 waitevent 2 round 20 externalcall yes



project-root/
├── app.js
├── package.json
├── .env
├── simulate.sh
├── routes/
│   ├── success/
│   │   ├── ok200.js
│   │   ├── created201.js
│   │   └── accepted202.js
│   └── error/
│       ├── asyncError.js
│       ├── customSpanError.js
│       ├── handledError.js
│       ├── jsonError.js
│       └── unhandledError.js


📊 Integrate with Datadog APM:
    To enable APM with Datadog:
    Ensure the Datadog Agent is running locally or in your container.
    Uncomment this line at the top of your app.js:

    require('dd-trace').init();


🧪 Available Endpoints

## ✅ Success Endpoints

| Endpoint            | Type | Description                                   |
|---------------------|------|-----------------------------------------------|
| `/success/200`      | GET  | 200 OK - Standard success                     |
| `/success/201`      | GET  | 201 Created - New resource created            |
| `/success/202`      | GET  | 202 Accepted - Request received, not yet done |

## ❌ Error Endpoints

| Endpoint                   | Type | Description                                  |
|---------------------------|------|----------------------------------------------|
| `/error/unhandled`        | GET  | Throws an unhandled server error             |
| `/error/handled`          | GET  | Returns a 500 error (handled gracefully)     |
| `/error/async`            | GET  | Fails an async function                      |
| `/error/custom-span`      | GET  | Triggers a manual custom span with error tag |
| `/error/json`             | POST | Fails on invalid JSON request body           |


