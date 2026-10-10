FROM cm2network/steamcmd:root

ARG MMS_BRANCH=1.12
ARG SM_BRANCH=1.12

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl lib32z1 \
 && rm -rf /var/lib/apt/lists/*

COPY install-sourcemod.sh entrypoint.sh /opt/l4d2/

# sed: por si los .sh se guardaron con finales de línea de Windows (CRLF)
RUN sed -i 's/\r$//' /opt/l4d2/*.sh \
 && chmod +x /opt/l4d2/*.sh \
 && /opt/l4d2/install-sourcemod.sh /opt/l4d2/sourcemod \
 && mkdir -p /home/steam/l4d2 \
 && chown -R steam:steam /home/steam/l4d2 /opt/l4d2

USER steam
WORKDIR /home/steam
EXPOSE 27015/tcp 27015/udp
ENTRYPOINT ["/opt/l4d2/entrypoint.sh"]
