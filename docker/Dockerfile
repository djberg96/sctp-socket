FROM ruby:3.3-slim

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    libsctp-dev \
    lksctp-tools \
    iproute2 \
    sudo \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    PATH="/bundle/bin:${PATH}"

COPY docker/run_specs.sh /usr/local/bin/run_specs
RUN chmod +x /usr/local/bin/run_specs

ENTRYPOINT ["/usr/local/bin/run_specs"]
