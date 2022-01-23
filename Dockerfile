FROM node:10
ENV SECRET_WORD=HelloWorld
EXPOSE 3000
COPY . .
RUN npm install
ENTRYPOINT ["npm", "start"]
