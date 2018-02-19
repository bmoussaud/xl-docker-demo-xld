FROM openjdk:jre-alpine
MAINTAINER XebiaLabs "info@xebialabs.com"
RUN mkdir -p /repository
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

COPY resources/deployit.conf /opt/xld/server/conf/deployit.conf
RUN ln -fs /opt/xld/server/repository /repository

RUN /opt/xld/server/bin/run.sh -setup -reinitialize -force && \
    ln -fs /license/deployit-license.lic /opt/xld/server/conf/deployit-license.lic && \
    rm -rf /opt/xld/server/log/* /opt/xld/server/tmp/*

COPY resources/supervisord.conf /etc/supervisord.conf
COPY resources/xld.conf /etc/supervisor/conf.d/xld.conf

RUN rm -rf /opt/xld/server/plugins/xld-kubernetes-*
ADD plugins/xld-kubernetes-plugin-7.5.1-SNAPSHOT.xldp  /opt/xld/server/plugins
ADD plugins/xld-smoke-test-plugin-1.0.4.xldp  /opt/xld/server/plugins
ADD plugins/kubernetes-custom-rules-1.0.jar  /opt/xld/server/plugins
ADD ext /opt/xld/server/ext
COPY resources/planner.conf /opt/xld/server/conf/planner.conf
COPY resources/xld-wrapper-linux.conf /opt/xld/server/conf/resources/xld-wrapper-linux.conf

RUN addgroup xl && adduser -D -H  -G xl xl

RUN chown -R xl:xl /opt/xld
RUN chmod -R 777 /opt/xld
USER xl
WORKDIR /opt/xld

CMD ["/usr/bin/supervisord"]

EXPOSE 4516
