# Use a less bloated image.
FROM node:22-alpine


# We don't want to run the application as root in the container, let's use
# the built-in node user of the node:22-alpine image instead.
USER node
RUN mkdir /home/node/app
WORKDIR /home/node/app

# Makes your builds more snappy by avoiding running npm install if dependencies are
# unchanged, due to docker image layer caching.
COPY package*json ./
RUN npm ci --omit=dev

COPY . .

CMD ["npm", "start"]
