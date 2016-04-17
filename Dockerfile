FROM oracle/oraclelinux
MAINTAINER Petr Klimenko [petrklim@yandex.ru]

# Install packages. TODO: Move install packages into script with clear
RUN yum install -y oracle-rdbms-server-12cR1-preinstall
RUN yum install -y curl unzip

# Setup env variables
ENV ORACLE_INSTALL_GROUP=oinstall \
    ORACLE_DBA_GROUP=dba \
    ORACLE_USER=oracle \
    ORACLE_UNQNAME=orcl

ENV ORACLE_USER_HOME=/home/oracle \
    ORACLE_ROOT=/oracle

ENV ORACLE_BASE=${ORACLE_ROOT}/database \
    ORACLE_INVENTORY_LOCATION=${ORACLE_ROOT}/oraInventory \
    ORACLE_INST_LOC_FILE=${ORACLE_USER_HOME}/oraInst.loc

ENV ORACLE_HOME=${ORACLE_BASE}/core \
    DISTRIB_URL=http://128.68.8.30:8080/database \
    DISTRIB_FOLDER=/tmp/database

# Some setup for oracle
RUN sed -i "s/\(^oracle.*memlock.*$\)/# \1/g" /etc/security/limits.d/oracle-rdbms-server-12cR1-preinstall.conf

RUN mkdir -p ${ORACLE_HOME} && \
    mkdir -p ${ORACLE_INVENTORY_LOCATION} && \
    chown -R ${ORACLE_USER}:${ORACLE_INSTALL_GROUP} ${ORACLE_ROOT}

ADD who /usr/bin/
RUN chmod 755 /usr/bin/who

# Prepare install script
WORKDIR ${ORACLE_USER_HOME}
ADD install.sh .
RUN chmod a+x install.sh

# Run install script
USER oracle
RUN ./install.sh

USER root
RUN ${ORACLE_HOME}/root.sh

# # Copy files
# WORKDIR ${ORACLE_USER_HOME}
# ADD files/ files
# ADD files/envsubst .
# RUN chmod 755 envsubst
# RUN ./envsubst ./files/.bashrc > .bashrc
# RUN ./envsubst ./files/oraInst.loc > ${ORACLE_INST_LOC_FILE}
# RUN ./envsubst ./files/install.sh > install.sh
# RUN ./envsubst ./files/run.sh > run.sh
# RUN chown -R ${ORACLE_USER}:${ORACLE_INSTALL_GROUP} .
# RUN chmod 755 install.sh
# RUN chmod 755 run.sh
#
# EXPOSE 22 1521
# CMD ./run.sh
