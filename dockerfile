FROM openresty/openresty:1.19.9.1-1-alpine-fat
COPY .docker/conf/nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf 
COPY .docker/conf/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY ./src /app
ENV http_proxy=http://192.168.3.32:1080
ENV https_proxy=http://192.168.3.32:1080

RUN cat /etc/apk/repositories && apk add git && \
    luarocks install lua-resty-http && \
    luarocks install lua-cjson && \
    luarocks install lua-resty-cookie && \
    luarocks install lua-resty-jwt && \
    unset http_proxy && unset https_proxy
WORKDIR /app