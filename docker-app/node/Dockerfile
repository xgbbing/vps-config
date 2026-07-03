FROM node:22-alpine

WORKDIR /usr/src/app/node

RUN apk add --no-cache \
  python3 \
  py3-setuptools \
  make \
  g++ \
  tzdata \
  sqlite \
  && ln -sf /usr/bin/python3 /usr/bin/python

COPY package*.json ./

RUN npm config set registry https://registry.npmmirror.com \
  && npm ci --omit=dev

COPY . .

# 创建数据库目录
RUN mkdir -p /usr/src/app/database

ENV TZ=Asia/Shanghai
ENV NODE_ENV=production
ENV PORT=3000

# 设置 Node.js 堆内存上限为 256MB
ENV NODE_OPTIONS="--max-old-space-size=256"

EXPOSE 3000

CMD ["node", "dist/app.js"]
