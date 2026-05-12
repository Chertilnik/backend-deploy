FROM node:20-alpine

COPY deploy-app /app
WORKDIR /app

RUN npm ci

ENV PORT=3000
EXPOSE 3000

CMD ["npm", "start"]