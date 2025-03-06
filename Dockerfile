FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get -q update && apt-get -qy --no-install-recommends install \
        perl \
        squid \
        apache2 \
        imagemagick \
        wget \
        libwww-perl \
        jp2a \
        supervisor \
    && apt-get clean \
    && apt-get autoclean

RUN sed -i "s/^#http_access allow localnet/http_access allow localnet/" /etc/squid/squid.conf
RUN sed -i "s/^http_port 3128/http_port 3128 transparent/" /etc/squid/squid.conf

COPY squid_config_extra.txt /tmp/squid_config_extra.txt
RUN cat /tmp/squid_config_extra.txt >> /etc/squid/squid.conf

RUN echo "*/10 * * * * proxy rm /var/www/images/*" >> /etc/crontab

RUN mkdir -p /var/www/images && \
    chown -R www-data:www-data /var/www/images && \
    chmod 775 /var/www/images

RUN usermod -aG www-data proxy && \
    usermod -aG proxy www-data
	
RUN wget "https://www.shutterstock.com/image-photo/carrot-isolated-on-white-background-600nw-795704785.jpg" -O /usr/local/bin/jeremie.jpg

COPY rewrite.pl /usr/local/bin/rewrite.pl
COPY tourette.pl /usr/local/bin/tourette.pl
COPY ascii.pl /usr/local/bin/ascii.pl
COPY watermark.pl /usr/local/bin/watermark.pl

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create swap directories so supervisor can start the process

RUN mkdir -p /usr/local/squid/var/cache_liligo \
    && chown proxy:proxy /usr/local/squid/var/cache_liligo \
    && /usr/sbin/squid -z -N --foreground \
    && chown proxy:proxy /usr/local/squid/var/cache_liligo \
    && mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && mkdir -p /var/run/squid /var/lock/squid /var/log/squid

VOLUME /var/www/images

EXPOSE 3128

CMD ["/usr/bin/supervisord", "-n"]
