# sausix/bind-sql-base-alpine:9.16.11
FROM alpine:3.13

LABEL maintainer "Adrian Sausenthaler <docker.sausix.removethispart@sausenthaler.de>"

ENV BIND_VERSION 9.16.11
ENV CONTAINER_DIR "/container"

RUN apk update && \
	apk add --no-cache python3 py3-ply py3-pip py3-jinja2 tzdata tini && \
	apk add --no-cache --virtual .build-deps \
	make gcc file musl-dev libuv-dev openssl-dev libxml2-dev json-c-dev krb5-dev protobuf-c-dev libcap-dev fstrm-dev libidn2-dev mariadb-dev mariadb-client python3-dev && \
	export BUILDDIR="$CONTAINER_DIR/build" && \
	export LOGDIR="$CONTAINER_DIR/log" && \
	mkdir -p "$BUILDDIR" && \
	mkdir -p "$LOGDIR" && \
	mkdir -p "$CONTAINER_DIR/init.d" && \
	cd "$BUILDDIR" && \
	wget https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz && \
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
	rm -rf "$BUILDDIR" "/var/cache/apk/*" && \
	addgroup -S named && \
	adduser -S -D -H -h /etc/bind -s /sbin/nologin -G named -g named named && \
	chown -R root:named /etc/bind

COPY "files/init" "$CONTAINER_DIR/"
COPY "files/00-printvars.sh" "$CONTAINER_DIR/init.d/"

ENTRYPOINT ["/sbin/tini", "--", "/bin/sh", "-e", "/container/init"]

CMD ["/bin/sh"]

# /etc/bind/bind.keys