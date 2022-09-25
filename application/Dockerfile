FROM node:18-alpine

# update packages
# RUN apk update

# create root application folder
WORKDIR /app

COPY package.json package-lock.json tsconfig.json ./

RUN npm install

COPY src ./src
RUN npm run build

EXPOSE 3000

CMD ["npm","start"]
# CMD ["sh","ls"]