FROM enonic/xp:7.6.1-ubuntu

# Elevate privileges
USER root

# Add some debugging tools
RUN apt-get update && apt-get -y install curl vim jq wget net-tools
RUN wget https://repo.enonic.com/public/com/enonic/cli/enonic/1.5.1/enonic_1.5.1_Linux_64-bit.tar.gz \
&& tar -xvzf enonic_1.5.1_Linux_64-bit.tar.gz \
&& mv enonic /usr/bin/enonic
ADD init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh && chown 1337 /usr/local/bin/init.sh

USER 1337
