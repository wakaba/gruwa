FROM quay.io/wakaba/docker-perl-app-base

ADD .git/ /app/.git/
ADD .gitmodules /app/.gitmodules
ADD Makefile /app/
ADD bin/ /app/bin/
ADD lib/ /app/lib/
ADD config/ /app/config/
ADD modules/ /app/modules/
ADD templates/ /app/templates/
ADD css/ /app/css/
ADD js/ /app/js/

RUN cd /app && \
    make deps-docker PMBP_OPTIONS=--execute-system-package-installer && \
    echo '#!/bin/bash' > /server && \
    echo 'cd /app' >> /server && \
    echo 'exec ./perl bin/server.pl 8080' >> /server && \
    chmod u+x /server && \
    rm -fr /app/.git /app/deps /app/t /app/t_deps && \
    rm -rf /var/lib/apt/lists/*

CMD ["/server"]
