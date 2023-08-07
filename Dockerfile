# Stage 1: Build the TypeScript app
FROM node:18.16.0-alpine as build

WORKDIR /usr/src/app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

RUN npm install

# Copy the .env file to the working directory
COPY .env .env

# Copy the rest of the application code
COPY . .

RUN npm run build

# Stage 2: Run the built JavaScript app
FROM node:18.16.0-alpine

# Set environment variables for OracleDB connection load by .env file
ARG DB_SID
ARG DB_DOMAIN
ARG DB_PORT
ARG DB_PASSWD
ARG DB_BUNDLE
ARG DB_USER
ARG DB_SCHEMA

WORKDIR /usr/src/app

# Copy the built JavaScript files from the previous stage
COPY --from=build /usr/src/app/dist ./dist

# Copy the package.json and package-lock.json files
COPY package*.json ./

RUN npm install --only=production

# Expose the port
EXPOSE 4000

CMD ["node", "./dist/index.js"]
