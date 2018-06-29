FROM buildpack-deps:jessie
LABEL maintainer="Peter Martini <PeterCMartini@GMail.com>, Zak B. Elep <zakame@cpan.org>"

COPY *.patch /usr/src/perl/
WORKDIR /usr/src/perl

RUN curl -SL https://www.cpan.org/src/5.0/perl-5.20.3.tar.bz2 -o perl-5.20.3.tar.bz2 \
    && echo '1b40068166c242e34a536836286e70b78410602a80615143301e52aa2901493b *perl-5.20.3.tar.bz2' | sha256sum -c - \
    && tar --strip-components=1 -xaf perl-5.20.3.tar.bz2 -C /usr/src/perl \
    && rm perl-5.20.3.tar.bz2 \
    && cat *.patch | patch -p1 \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && archBits="$(dpkg-architecture --query DEB_BUILD_ARCH_BITS)" \
    && archFlag="$([ "$archBits" = '64' ] && echo '-Duse64bitall' || echo '-Duse64bitint')" \
    && ./Configure -Darchname="$gnuArch" "$archFlag" -Dusethreads -Duseshrplib -Dvendorprefix=/usr/local  -des \
    && make -j$(nproc) \
    && TEST_JOBS=$(nproc) make test_harness \
    && make install \
    && cd /usr/src \
    && curl -LO http://www.cpan.org/authors/id/M/MI/MIYAGAWA/App-cpanminus-1.7044.tar.gz \
    && echo '9b60767fe40752ef7a9d3f13f19060a63389a5c23acc3e9827e19b75500f81f3 *App-cpanminus-1.7044.tar.gz' | sha256sum -c - \
    && tar -xzf App-cpanminus-1.7044.tar.gz && cd App-cpanminus-1.7044 && perl bin/cpanm . && cd /root \
    && rm -fr ./cpanm /root/.cpanm /usr/src/perl /usr/src/App-cpanminus-1.7044* /tmp/*

WORKDIR /root

# Install perl and dependency packages
RUN apt-get update
#RUN apt-get install build-essential
#RUN apt-get install libpq-dev
RUN yes | cpan Config::AutoConf Path::Tiny
RUN yes | cpan MongoDB
RUN yes | perl -MCPAN -e 'install DBI'

CMD ["perl5.20.3","-de0"]
