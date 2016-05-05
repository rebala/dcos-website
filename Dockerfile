FROM nginx:stable

RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done \
  && apt-get update && apt-get install -y git curl xz-utils

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 5.11.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

COPY  . /dcos-website
WORKDIR /dcos-website

ENV CI true

RUN git submodule update --init --recursive \
  && npm install && npm start \
  && rm -rf /usr/share/nginx/html/* \
  && cp -r build/* /usr/share/nginx/html/ \
  && ln -sf /usr/share/nginx/html/docs/1.7 /usr/share/nginx/html/docs/latest \
  && bash ci/generate-nginx-conf.sh > /etc/nginx/conf.d/default.conf \
  && apt-get remove -yf curl git xz-utils \
  && apt-get autoremove -yf \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && rm -rf /dcos-website/*

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]