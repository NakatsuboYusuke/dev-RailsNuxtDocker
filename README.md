# README
This Repository is for Third Study Nuxt.js + Ruby on Rails API + Docker<br>

- Frontend Nuxt.js
- Backend Ruby on Rails API

## 環境
- Ruby 2.6.5
- Ruby on Rails API 5.2.3
- Node 12.0.0
- yarn 1.17.3
- Nuxt.js 2.6.11
- PostgreSQL 11.5
- Docker 19.03.5

```
$ ruby -v
$ node -v
$ yarn -v
$ psql -V
$ docker version
```

```
// Node.jsのバージョン管理
$ brew install node
$ npm install -g n
$ n list

// 最新バージョン
$ n latest
$ node -v

// 指定バージョン
$ n 12.0.0
$ node -v
// => v12.0.0
```

## プロジェクトを生成

### Ruby on Rails APIを生成

```
$ rails new backend --api -d postgresql
```

### Nuxt.jsを生成

```
$ yarn create nuxt-app frontend
```

### Dockerのコンテナを作成

#### ファイル構成

```
projectName
| -- docker-compose.yml
| -- Backend
|  | -- Gemfile
|  | -- Gemfile.lock
|  | -- Dockerfile
| -- Frontend
|  | -- Dockerfile
```

- docker-compose.ymlを生成

```
# docker-compose.yml

version: '3'
services:
  db:
    container_name: app_db
    image: postgres:11.5
    environment:
      - TZ=Asia/Tokyo
    volumes:
      - ./backend/db/pgdata:/var/lib/postgresql/data

  backend:
    container_name: app_backend
    build: ./backend
    command: /bin/bash -c "rm -rf tmp/pids/server.pid; bundle exec rails s -p 3000 -b 0.0.0.0"
    volumes:
      - ./backend:/app/backend
    ports:
      - '3000:3000'
    depends_on:
      - db

  frontend:
    container_name: app_frontend
    build: ./frontend
    command: yarn dev
    volumes:
      - ./frontend:/app/frontend
    ports:
      - '8080:3000'
    depends_on:
      - backend
```

- frontend/Dockerfileを生成

```
# frontend/Dockerfile

FROM node:12.0.0

ENV APP_DIR /app/frontend
ENV PATH /app/frontend/node_modules/.bin:$PATH
ENV TZ Asia/Tokyo
ENV HOST 0.0.0.0

RUN mkdir -p /app/frontend
WORKDIR $APP_DIR
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
COPY package.json $APP_DIR/package.json
COPY yarn.lock $APP_DIR/yarn.lock
RUN yarn install
COPY . $APP_DIR
```

- backend/Dockerfileを生成

```
# backend/Dockerfile

FROM ruby:2.6.5

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql-client nodejs

ENV APP_DIR /app/backend

RUN mkdir -p /app/backend
WORKDIR $APP_DIR
COPY Gemfile $APP_DIR/Gemfile
COPY Gemfile.lock $APP_DIR/Gemfile.lock
RUN gem install bundler
RUN bundle install
COPY . $APP_DIR
```

- database.ymlを編集

```
# api/config/database.yml

:<snip>

development:
  <<: *default
  database: postgres
  username: postgres
  password:
  host: db

:<snip>
```

- コンテナをビルド

```
$ docker-compose build
```

- データベースを生成

```
$ docker-compose run --rm backend rails db:create
```

- ローカルサーバーにアクセスし動作を確認

```
# Ruby on Rails API
http://localhost:3000/

# Nuxt.js
http://localhost:8080/
```
