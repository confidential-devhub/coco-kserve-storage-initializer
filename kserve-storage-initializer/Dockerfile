FROM quay.io/modh/kserve-storage-initializer:rhoai-2.16

USER 0

WORKDIR /storage-initializer/scripts

RUN microdnf install -y openssl tar gzip

RUN mkdir keys && chmod 777 keys

RUN mv initializer-entrypoint download-model

ADD decrypt.sh ./initializer-entrypoint

RUN chmod +x initializer-entrypoint