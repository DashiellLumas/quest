FROM node
EXPOSE 80
COPY package.json package.json
RUN npm install
COPY server.js server.js
COPY survivors.json survivors.json
CMD ["node", "server.js"]
