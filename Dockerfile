# sausix/bind-sql-base-alpine:9.16.11
FROM alpine:3.13

LABEL maintainer "Adrian Sausenthaler <docker.sausix.removethispart@sausenthaler.de>"

ENV CONTAINER_DIR "/container"
ENV BIND_VERSION 9.16.11
ENV BIND_SRC_MD5 58cbc23121e43ec934d644c4f412ceea

RUN apk update && \
	apk add --no-cache tzdata tini dnssec-root dns-root-hints bind-libs libcap libidn2 mariadb-connector-c python3 py3-ply py3-bind py3-jinja2 && \
	apk add --no-cache --virtual .build-deps \
	make gcc file musl-dev libuv-dev openssl-dev libxml2-dev json-c-dev krb5-dev protobuf-c-dev libcap-dev fstrm-dev libidn2-dev mariadb-dev python3-dev && \
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
		--with-dlopen=yes \
		--with-gssapi=/usr \
		--with-libtool \
		--with-openssl=/usr \
		--with-libidn2 \
		--with-dlz-mysql \
		--with-dlz-filesystem=yes \
		--with-libxml2 \
		--with-json-c \
		--enable-fixed-rrset \
		--enable-full-report \
		--enable-dnstap \
		--enable-largefile \
		--enable-linux-caps \
		--enable-shared \
		--enable-static \
		--disable-isc-spnego \
		--disable-backtrace \
		--disable-symtable > $LOGDIR/configure.log 2> $LOGDIR/configure.err && \
	echo "make... (please wait)" && \
	make > $LOGDIR/make.log 2> $LOGDIR/make.err && \
	echo "make install... (please wait)" && \
	make install > $LOGDIR/make_install.log 2> $LOGDIR/make_install.err && \
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

ENTRYPOINT ["/sbin/tini", "--", "/bin/sh", "-e", "/container/init"]

CMD ["/bin/sh"]
