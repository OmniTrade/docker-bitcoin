FROM debian:stretch-slim

ENV BITCOIN_VERSION 0.16.3
ENV BITCOIN_URL https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz
ENV BITCOIN_SHA256 5d422a9d544742bc0df12427383f9c2517433ce7b58cf672b9a9b17c2ef51e4f
# ENV BITCOIN_ASC_URL https://bitcoin.org/bin/bitcoin-core-$BITCOIN_VERSION/SHA256SUMS.asc
# ENV BITCOIN_PGP_KEY 01EA5486DE18A882D4C2684590C8019E36C2E964
# Vars related to data directory creation 
ENV BITCOIN_DATA /data

COPY docker-entrypoint.sh /entrypoint.sh
COPY rabbitmqadmin /usr/bin/rabbitmqadmin
COPY google-logger /usr/bin/google-logger


RUN groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin \
    && set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget python-setuptools python-pip procps htop\
	&& rm -rf /var/lib/apt/lists/* \
# run pip
    && pip install --upgrade google-cloud-logging \
    && pip install --upgrade grpcio==1.7.3 \
# install bitcoin binaries
    && set -ex \
	&& cd /tmp \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256 bitcoin.tar.gz" | sha256sum -c - \
#	&& gpg --keyserver keyserver.ubuntu.com --recv-keys "$BITCOIN_PGP_KEY" \
#	&& wget -qO bitcoin.asc "$BITCOIN_ASC_URL" \
#	&& gpg --verify bitcoin.asc \
	&& tar -xzvf bitcoin.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt \
	&& rm -rf /tmp/* \
# create data directory
    && mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin \
# set permissions to files
    && chmod +x /usr/bin/rabbitmqadmin \
    && chmod +x /usr/bin/google-logger

VOLUME /data

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8332 8333 18332 18333
CMD ["bitcoind"]
