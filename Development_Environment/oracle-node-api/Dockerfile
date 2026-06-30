FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache podman

COPY package.json ./
RUN npm install --omit=dev

COPY src ./src

ENV PORT=8090
EXPOSE 8090

CMD ["npm", "start"]
