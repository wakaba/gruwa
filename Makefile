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

deps: git-submodules pmbp-install build deps-rev
deps-docker:         pmbp-install

git-submodules:
	$(GIT) submodule update --init

deps-rev:
	$(GIT) rev-parse HEAD > rev

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

js/sha1.js: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/emn178/js-sha1/master/src/sha1.js

build: build-deps build-main
build-deps: git-submodules pmbp-install
build-main: css/themes.css themes.json js/sha1.js \
    js/components.js css/components.css db/gruwa.sql

db/gruwa.sql: db/gruwa-*.sql
	cat db/gruwa-*.sql > $@

GRUWA_THEMES_DIR = ../gruwa-themes

themes.json: css/themes.css
css/themes.css: bin/generate-themes.pl $(GRUWA_THEMES_DIR)
	$(PERL) $< $(GRUWA_THEMES_DIR)

js/components.js: local/unit-number.js local/page-components.js local/time.js \
    local/qrcode.js
	cat local/unit-number.js local/page-components.js \
	    local/time.js local/qrcode.js > $@
css/components.css: local/unit-number.css local/page-components.css
	cat local/unit-number.css local/page-components.css > $@

local/unit-number.js: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/html-unit-number/master/src/unit-number.js
local/unit-number.css: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/html-unit-number/master/css/default.css
local/page-components.js: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/html-page-components/master/src/page-components.js
local/maps.js: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/html-page-components/master/src/maps.js
local/qrcode.js: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/html-page-components/master/src/qrcode.js
local/page-components.css: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/html-page-components/master/css/default.css
local/time.js: local/generated
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/timejs/master/src/time.js

local/generated:
	touch $@

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: git-submodules pmbp-install local/accounts.sql local/apploach.sql

deps-circleci: test-deps deps-rev

local/accounts.sql: local/accounts-2.sql
	cp $< $@
local/accounts-2.sql:
	curl https://raw.githubusercontent.com/wakaba/accounts/master/db/account.sql > $@
local/apploach.sql: local/apploach-2.sql
	cp $< $@
local/apploach-2.sql:
	curl https://raw.githubusercontent.com/wakaba/apploach/master/db/apploach.sql > $@

test-main: test-http test-browser

test-http:
	$(PROVE) t/http/*.t

test-browser:
	TEST_MAX_CONCUR=1 $(PROVE) t/browser/*.t

test-http-circleci: test-http
test-browser-circleci: test-browser

## License: Public Domain.
