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

- サービスの構築、再構築

```
$ docker-compose build
```

- データベースを生成

```
$ docker-compose run --rm backend rails db:create
```

- コンテナを作成、開始

```
$ docker-compose up
```

- ローカルサーバーにアクセスし動作を確認

```
# Ruby on Rails API
http://localhost:3000/

# Nuxt.js
http://localhost:8080/

// サービスの停止
$ docker-compose stop

// コンテナの停止
$ docker-compose down
```

### バックエンドの作成

- バックエンドのコンテナに接続

```
// $ docker-compose exec コンテナ名 bash

$ docker-compose exec backend bash
```

- scaffoldでリストを作成

```
#rails g scaffold List title:string excerpt:text
#rails db:migrate

// seedデータを追加
# backend/db/seeds.rb
3.times {|n| List.create(title: "Test-title-#{n}", excerpt: "Test-excerpt-#{n}")}

#rails db:seed
```

- ルーティングを編集

```
# backend/config/routes.rb

Rails.application.routes.draw do
  namespace :api, format: 'json' do
    namespace :v1 do
      resources :lists
    end
  end
end
```

- コントローラを編集

```
# backend/app/controllers/api/v1/lists_controller.rb

module Api::V1
  class ListsController < ApplicationController
    before_action :set_list, only: [:show, :update, :destroy]

    # GET /lists
    def index
      @lists = List.all

      render json: @lists
    end

    # GET /lists/1
    def show
      render json: @list
    end

    # POST /lists
    def create
      @list = List.new(list_params)

      if @list.save
        render json: @list, status: :created, location: @list
      else
        render json: @list.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /lists/1
    def update
      if @list.update(list_params)
        render json: @list
      else
        render json: @list.errors, status: :unprocessable_entity
      end
    end

    # DELETE /lists/1
    def destroy
      @list.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_list
      @list = List.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def list_params
      params.require(:list).permit(:title, :excerpt)
    end
  end
end
```

- ルートにアクセスしJSONが返ってきているか確認する

```
http://localhost:3000/api/v1/lists
```

### フロントエンドの作成

- プロキシを設定する<br>
フロントエンドからのリクエストを、APIのエンドポイント(URI)にプロキシさせる

```

export default {
  :<snip>
  axios: {
    proxy: true
  },
  proxy: {
    '/api/v1/': {
      target: 'http://localhost:3000/api/v1/lists',
      pathRewrite: {
        '^/api/v1/': '/api/v1/'
      },
    }
  }
}

```

- CORSを設定する

```
# backend/Gemfile

gem 'rack-cors'


# backend/config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # frontendのコンテナip
    origins '192.168.32.4:3000'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end


# bundle install
```

###### これ以降の変更についてはエラーが発生しているので、修正する
