all:

WGET = wget
CURL = curl
GIT = git

updatenightly: local/bin/pmbp.pl
	$(CURL) -s -S -L -f https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add modules t_deps/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config

## ------ Setup ------

deps: git-submodules pmbp-install

git-submodules:
	$(GIT) submodule update --init

PMBP_OPTIONS=

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(CURL) -s -S -L -f https://raw.githubusercontent.com/wakaba/perl-setupenv/master/bin/pmbp.pl > $@
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --install \
            --create-perl-command-shortcut @perl \
            --create-perl-command-shortcut @prove \
            --create-perl-command-shortcut @lserver=perl\ bin/local.pl

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps deps-accounts deps-minio

deps-accounts:
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) \
	    --install-perl-app https://github.com/wakaba/accounts

deps-minio: local/bin/minio

local/bin/minio:
	$(WGET) -O $@ https://dl.minio.io/server/minio/release/linux-amd64/minio
	chmod u+x $@

test-main:
	$(PROVE) t/http/*.t

## License: Public Domain.
