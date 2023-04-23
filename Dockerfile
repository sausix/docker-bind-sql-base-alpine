# sausix/bind-sql-base-alpine:latest
FROM alpine:3.17

LABEL maintainer "Adrian Sausenthaler <docker.sausix.removethispart@sausenthaler.de>"

ENV CONTAINER_DIR "/container"

#ENV BIND_VERSION 9.19.11
#ENV BIND_SRC_MD5 55846f3f003cff7900af70abb5693ba9

ENV BIND_VERSION 9.18.14
ENV BIND_SRC_MD5 abcced8ffa94816bd196f7814fceefd1

RUN apk update && \
	apk add --no-cache tzdata tini dnssec-root bind-dnssec-root dns-root-hints bind-libs libcap libidn2 mariadb-connector-c json-c jemalloc python3 py3-ply py3-jinja2 && \
	apk add --no-cache --virtual .build-deps \
	make gcc file musl-dev libuv-dev openssl-dev libxml2-dev json-c-dev krb5-dev protobuf-c-dev libcap-dev fstrm-dev libidn2-dev mariadb-dev userspace-rcu-dev nghttp2-dev jemalloc-dev perl readline-dev py3-dnspython py3-pytest python3-dev && \
	export BUILDDIR="$CONTAINER_DIR/build" && \
	export LOGDIR="$CONTAINER_DIR/buildlog" && \
	mkdir -p "$BUILDDIR" && \
	mkdir -p "$LOGDIR" && \
	mkdir -p "$CONTAINER_DIR/init.d" && \
	cd "$BUILDDIR" && \
	wget https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz && \
	echo "${BIND_SRC_MD5}  bind-${BIND_VERSION}.tar.xz" | md5sum -cs - && \
	tar -xf bind-${BIND_VERSION}.tar.xz && \
	cd bind-${BIND_VERSION} && \
	export CFLAGS="-D_GNU_SOURCE" && \
	echo "configure... (please wait)" && \
	./configure \
--sysconfdir=/etc/bind \
--localstatedir=/var \
--infodir=/usr/share/info \
--with-gssapi \
--with-openssl=/usr \
--with-libidn2 \
--with-libxml2 \
--with-json-c \
--enable-fixed-rrset \
--enable-full-report \
--enable-dnstap \
--enable-largefile \
--enable-geoip \
--enable-shared > $LOGDIR/configure.log 2> $LOGDIR/configure.err && \
	echo "make... (please wait)" && \
	make > $LOGDIR/make.log 2> $LOGDIR/make.err && \
	echo "make install... (please wait)" && \
	make install > $LOGDIR/make_install.log 2> $LOGDIR/make_install.err && \
	cd contrib/dlz/modules/mysql/ && \
	make > $LOGDIR/mysql.make.log 2> $LOGDIR/mysql.make.err && \
	make install > $LOGDIR/mysql_make_install.log 2> $LOGDIR/mysql_make_install.err && \
	apk del -r .build-deps && \
	cd / && \
	rm -rf "$BUILDDIR" "/var/cache/apk/*" "/etc/bind/bind.keys" && \
	addgroup -S named && \
	adduser -S -D -H -h /etc/bind -s /sbin/nologin -G named -g named named && \
	mkdir -p -m 770 /var/named && \
	mkdir -p -m 755 /run/named && \
	chown named:named /run/named && \
	mkdir -p ${CONTAINER_DIR}/bind-config && \
	mkdir -p ${CONTAINER_DIR}/default-zones && \
	mkdir -p -m 750 /var/log/bind

COPY "files/init" "$CONTAINER_DIR/"
COPY "files/*.zone" "$CONTAINER_DIR/default-zones/"

VOLUME ["/var/named", "/etc/bind"]

ENTRYPOINT ["/sbin/tini", "--", "/container/init"]

CMD ["/bin/sh"]
