# Use the official Node.js image
FROM cypress/browsers:latest

# Set the working directory
WORKDIR /app

# Install cron
USER root
RUN apt-get update && apt-get install -y cron && rm -rf /var/lib/apt/lists/*

# Create a low-privileged user
RUN useradd -m -s /bin/bash cypressuser

# Set Cypress cache directory to a shared location
ENV CYPRESS_CACHE_FOLDER=/home/cypressuser/.cache/Cypress
ENV CYPRESS_RUN_BINARY=$CYPRESS_CACHE_FOLDER/13.7.2/Cypress/Cypress

# Copy package.json and package-lock.json (if using npm)
COPY package*.json ./

# Clean npm cache to avoid any issues with old packages
RUN npm cache clean --force

# Install project dependencies
RUN npm install --ignore-scripts

# Change ownership of the working directory to the non-root user
RUN chown -R cypressuser:cypressuser /app

# Switch to cypressuser before installing Cypress
USER cypressuser

# Ensure the Cypress cache directory exists
RUN mkdir -p $CYPRESS_CACHE_FOLDER && chmod -R 777 $CYPRESS_CACHE_FOLDER

# Install Cypress
RUN npm install cypress@13.7.2 --save-exact --save-dev

# Manually install Cypress binary
RUN CYPRESS_CACHE_FOLDER=$CYPRESS_CACHE_FOLDER npx cypress install

# Verify Cypress installation
RUN CYPRESS_CACHE_FOLDER=$CYPRESS_CACHE_FOLDER npx cypress verify || npx cypress install

# Copy the rest of your project files
USER root
COPY . .
COPY .env .env

# Change ownership of /app directory to the new user
RUN chown -R cypressuser:cypressuser /app /home/cypressuser/.cache

# Create necessary directories and log files with correct permissions
RUN mkdir -p /var/run/cron /var/log && \
    touch /var/log/cypress_cron.log && \
    chmod 666 /var/log/cypress_cron.log

# Set environment variables for cron to ensure correct path
RUN echo "PATH=/usr/local/bin:$PATH" >> /etc/environment

# Switch to the cypressuser
USER cypressuser

# Set up cron job
#/bin/bash -c 'source /app/.env &&
RUN echo "*/20 * * * * /bin/bash -c 'source /app/.env && cd /app && /usr/local/bin/node /app/node_modules/.bin/cypress run' >> /var/log/cypress_cron.log 2>&1" | crontab -

# Switch back to root to start cron
USER root

# Start the cron service and keep the container running
CMD ["sh", "-c", "cron && tail -f /var/log/cypress_cron.log"]