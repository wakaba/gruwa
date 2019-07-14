all:

WGET = wget
CURL = curl
GIT = git
PERL = ./perl

updatenightly: local/bin/pmbp.pl
	$(CURL) -s -S -L -f https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add modules t_deps/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

## ------ Setup ------

deps: git-submodules pmbp-install build
deps-docker:         pmbp-install

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
            --create-perl-command-shortcut @lserver=perl\ bin/local-server.pl

js/sha1.js:
	$(WGET) -O $@ https://raw.githubusercontent.com/emn178/js-sha1/master/src/sha1.js

build: build-deps build-main
build-deps: git-submodules pmbp-install
build-main: css/themes.css themes.json js/sha1.js

GRUWA_THEMES_DIR = ../gruwa-themes

themes.json: css/themes.css
css/themes.css: bin/generate-themes.pl $(GRUWA_THEMES_DIR)
	$(PERL) $< $(GRUWA_THEMES_DIR)

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: git-submodules pmb-install local/accounts.sql

deps-circleci: test-deps

local/accounts.sql: local/accounts-2.sql
	cp $< $@
local/accounts-2.sql:
	curl https://raw.githubusercontent.com/wakaba/accounts/master/db/account.sql > $@

test-main: test-http test-browser

test-http:
	$(PROVE) t/http/*.t

test-browser:
	TEST_MAX_CONCUR=1 $(PROVE) t/browser/*.t

test-http-circleci: test-http
test-browser-circleci: test-browser

## License: Public Domain.
