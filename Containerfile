FROM php:8.5-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        iputils-ping \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libzip-dev \
    && curl -fsSLo /tmp/sqlite.tar.gz https://sqlite.org/2026/sqlite-autoconf-3540100.tar.gz \
    && test "$(openssl dgst -sha3-256 /tmp/sqlite.tar.gz | awk '{print $NF}')" = "b6ced585c750916b1052667239a12c25a7ff34e7f06e1e6e01ecb0427657d9c4" \
    && mkdir /tmp/sqlite \
    && tar -xzf /tmp/sqlite.tar.gz -C /tmp/sqlite --strip-components=1 \
    && cd /tmp/sqlite \
    && ./configure --prefix=/usr/local --enable-shared --disable-static \
    && make -j"$(nproc)" \
    && make install \
    && ldconfig \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" exif gd zip \
    && rm -f /tmp/sqlite.tar.gz \
    && rm -rf /tmp/sqlite \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www

COPY bootstrap.php version.php ./
COPY public/ ./public/
COPY resources/ ./resources/
COPY scripts/ ./scripts/
COPY src/ ./src/
COPY templates/ ./templates/
COPY containers/php/entrypoint.sh /usr/local/bin/netarium-entrypoint
COPY containers/php/zz-netarium.ini /usr/local/etc/php/conf.d/zz-netarium.ini

RUN php -r 'if (PHP_VERSION_ID < 80505) { fwrite(STDERR, "PHP 8.5.5 or newer is required\n"); exit(1); } if (version_compare(SQLite3::version()["versionString"], "3.51.3", "<")) { fwrite(STDERR, "SQLite 3.51.3 or newer is required\n"); exit(1); } foreach (["exif", "fileinfo", "gd", "mbstring", "pdo_sqlite", "session", "sqlite3", "zip"] as $extension) { if (!extension_loaded($extension)) { fwrite(STDERR, "Missing PHP extension: {$extension}\n"); exit(1); } }'
RUN chmod 0755 /usr/local/bin/netarium-entrypoint

RUN printf '\nclear_env = no\nsecurity.limit_extensions = .php\n' \
    >> /usr/local/etc/php-fpm.d/www.conf

ENV NETARIUM_STORAGE_DIR=/var/lib/netarium

EXPOSE 9000

USER www-data
ENTRYPOINT ["/usr/local/bin/netarium-entrypoint"]
CMD ["php-fpm", "-F"]
