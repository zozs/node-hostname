FROM node:22-alpine

USER node
RUN mkdir /home/node/app
WORKDIR /home/node/app

COPY package*json ./
RUN npm ci --omit=dev

COPY . .

CMD ["npm", "start"]
