FROM enonic/xp:7.2.0-ubuntu

# Elevate privileges
USER root

RUN apt-get update && apt-get -y install curl vim
RUN wget http://repo.enonic.com/public/com/enonic/cli/enonic/1.0.12/enonic_1.0.12_Linux_64-bit.tar.gz \
&& tar -xvzf enonic_1.0.12_Linux_64-bit.tar.gz \
&& mv enonic /usr/bin/enonic
COPY config $XP_HOME/config
RUN mkdir -p $XP_HOME/data/dump
RUN chown -R $XP_USER $XP_ROOT
ADD init-entrypoint.sh /init-entrypoint.sh
RUN chmod +x /init-entrypoint.sh

# De-elevate privileges
USER 1337

ENTRYPOINT ["./init-entrypoint.sh"]
CMD []
