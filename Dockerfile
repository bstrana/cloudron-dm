FROM cloudron/base:4.2.0@sha256:46da2fffb36353ef714f97ae8e962bd2c212ca091108d768ba473078319a47f4

# Install Node.js 20 LTS and build dependencies
RUN apt-get update && \
    apt-get install -y curl gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y \
        nodejs \
        build-essential \
        python3 \
        nginx \
        supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app/code

# Copy package files first (for better layer caching)
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Build React frontend
RUN npm run build

# Create necessary directories
RUN mkdir -p /app/data \
             /run/nginx \
             /run/supervisor \
             /var/log/supervisor && \
    ln -sf /run/nginx /var/lib/nginx

# Copy configuration files
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /app/code/start.sh
RUN chmod +x /app/code/start.sh

# Expose port
EXPOSE 3000

CMD ["/app/code/start.sh"]
