# Stage 1: Build (Etape de construction)
FROM node:18-slim AS builder
WORKDIR /usr/local/app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Final (Etape de production - l'image finale sera tres legere)
FROM node:18-slim AS final
WORKDIR /usr/local/app
# On ne copie que le resultat propre depuis le builder
COPY --from=builder /usr/local/app .
EXPOSE 80
CMD ["node", "server.js"]

