#!/bin/bash

echo "🔧 Installing dependencies..."
npm install

# Optional: install dotenv-cli if needed
# npm install -g dotenv-cli

echo "📄 Creating .env file..."
cat <<EOL > .env
DD_SERVICE=node-error-demo
DD_ENV=development
DD_VERSION=1.0.0
PORT=3000
EOL

echo "🚀 Starting the server..."
node app.js
