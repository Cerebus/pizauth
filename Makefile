PREFIX ?= /usr/local
BINDIR ?= ${PREFIX}/bin
LIBDIR ?= ${PREFIX}/lib
SHAREDIR ?= ${PREFIX}/share
EXAMPLESDIR ?= ${SHAREDIR}/examples

MANDIR.${PREFIX} = ${PREFIX}/share/man
MANDIR./usr/local = /usr/local/man
MANDIR. = /usr/share/man
MANDIR ?= ${MANDIR.${PREFIX}}

.PHONY: all install test distrib

RUNNINGSYSTEMD=$(shell test -d /run/systemd/system/ && echo yes || echo no)
ifeq ($(USESYSTEMD), 0)
	INSTALLSYSTEMD :=
	SYSTEMD_FEATURE :=
else ifneq ($(RUNNINGSYSTEMD), yes)
	INSTALLSYSTEMD :=
	SYSTEMD_FEATURE :=
else
	INSTALLSYSTEMD := install-systemd
	SYSTEMD_FEATURE := --features=systemd
endif

all: target/release/pizauth

target/release/pizauth:
	cargo build --release $(SYSTEMD_FEATURE)

install: target/release/pizauth ${INSTALLSYSTEMD}
	install -d ${DESTDIR}${BINDIR}
	install -c -m 555 target/release/pizauth ${DESTDIR}${BINDIR}/pizauth
	install -d ${DESTDIR}${MANDIR}/man1
	install -d ${DESTDIR}${MANDIR}/man5
	install -c -m 444 pizauth.1 ${DESTDIR}${MANDIR}/man1/pizauth.1
	install -c -m 444 pizauth.conf.5 ${DESTDIR}${MANDIR}/man5/pizauth.conf.5
	install -d ${DESTDIR}${EXAMPLESDIR}/pizauth
	install -c -m 444 examples/pizauth.conf ${DESTDIR}${EXAMPLESDIR}/pizauth/pizauth.conf
	install -d ${DESTDIR}${SHAREDIR}/bash-completion/completions
	install -c -m 444 share/bash/completion.bash ${DESTDIR}${SHAREDIR}/bash-completion/completions/pizauth
	install -d ${DESTDIR}${SHAREDIR}/fish/vendor_completions.d
	install -c -m 444 share/fish/pizauth.fish ${DESTDIR}${SHAREDIR}/fish/vendor_completions.d
	install -d ${DESTDIR}${SHAREDIR}/zsh/site-functions
	install -c -m 444 share/zsh/_pizauth ${DESTDIR}${SHAREDIR}/zsh/site-functions/_pizauth

install-systemd:
	install -d ${DESTDIR}${LIBDIR}/systemd/user
	install -c -m 444 lib/systemd/user/pizauth.service ${DESTDIR}${LIBDIR}/systemd/user/pizauth.service

test:
	cargo test $(SYSTEMD_FEATURE)
	cargo test --release $(SYSTEMD_FEATURE)

distrib:
	test "X`git status --porcelain`" = "X"
	@read v?'pizauth version: ' \
	  && mkdir pizauth-$$v \
	  && cp -rp Makefile build.rs Cargo.lock Cargo.toml \
	    COPYRIGHT LICENSE-APACHE LICENSE-MIT \
	    CHANGES.md README.md \
	    pizauth.1 pizauth.conf.5 \
	    examples lib share src tests \
	      pizauth-$$v \
	  && tar cfz pizauth-$$v.tgz pizauth-$$v \
	  && rm -rf pizauth-$$v
