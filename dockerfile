FROM osins/openresty-deps
COPY ./src /app
WORKDIR /app