FROM openjdk:jre-alpine
MAINTAINER XebiaLabs "info@xebialabs.com"

RUN apk --no-cache add supervisor wget

RUN wget --progress=dot:giga -O /tmp/xl-deploy-trial-server.zip https://dist.xebialabs.com/xl-deploy-trial-server.zip && \
    mkdir -p /opt/xld && \
    unzip /tmp/xl-deploy-trial-server.zip -d /opt/xld && \
    mv /opt/xld/xl-deploy-*-server /opt/xld/server && \
    rm -rf /tmp/xl-deploy-trial-server.zip

RUN wget --progress=dot:giga -O /tmp/xl-deploy-trial-cli.zip https://dist.xebialabs.com/xl-deploy-trial-cli.zip && \
    mkdir -p /opt/xld && \
    unzip /tmp/xl-deploy-trial-cli.zip -d /opt/xld && \
    mv /opt/xld/xl-deploy-*-cli /opt/xld/cli && \
    rm -rf /tmp/xl-deploy-trial-cli.zip

ADD resources/deployit.conf /opt/xld/server/conf/deployit.conf

RUN /opt/xld/server/bin/run.sh -setup -reinitialize -force && \
    ln -fs /license/deployit-license.lic /opt/xld/server/conf/deployit-license.lic && \
    rm -rf /opt/xld/server/log/* /opt/xld/server/tmp/*

ADD resources/supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]

EXPOSE 4516
