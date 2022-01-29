FROM node:10
EXPOSE 3000
COPY . .
RUN npm install
ENTRYPOINT ["npm", "start"]
