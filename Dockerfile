# FROM node:18.16.0-alpine
# WORKDIR /app
# COPY package*.json ./
# RUN npm install
# COPY . .
# COPY .env .env
# RUN npm run build
# EXPOSE 4000
# CMD ["npm","start"]


# Stage 1: Build the TypeScript app
FROM node:18.16.0-alpine as build

WORKDIR /usr/src/app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

RUN npm install

# Copy the rest of the application code
COPY . .

RUN npm run build

# Stage 2: Run the built JavaScript app
FROM node:18.16.0-alpine

WORKDIR /usr/src/app

# Copy the built JavaScript files from the previous stage
COPY --from=build /usr/src/app/dist ./dist

# Copy the package.json and package-lock.json files
COPY package*.json ./

RUN npm install --only=production

# Expose the port
EXPOSE 4000

# Set environment variables for OracleDB connection
ENV DB_SID=ORCLPDBQAS
ENV DB_DOMAIN=20.105.170.70
ENV DB_PORT=1521
ENV DB_PASSWD=P@$$word1234
ENV DB_BUNDLE=basic
ENV DB_USER=SEM_CHR_GIS
ENV DB_SCHEMA=docker_oracle

CMD ["node", "./dist/index.js"]
