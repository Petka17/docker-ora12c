FROM oracle/oraclelinux
MAINTAINER Petr Klimenko [petrklim@yandex.ru]

# Install packages. TODO: Move install packages into separete script with clear
RUN yum install -y oracle-rdbms-server-12cR1-preinstall
RUN yum install -y curl unzip

# Init argument
ARG DISTRIB_URL

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
    DISTRIB_URL=${DISTRIB_URL} \
    DISTRIB_FOLDER=/tmp/database

# Some setup for oracle
RUN sed -i "s/\(^oracle.*memlock.*$\)/# \1/g" /etc/security/limits.d/oracle-rdbms-server-12cR1-preinstall.conf

RUN mkdir -p ${ORACLE_HOME} && \
    mkdir -p ${ORACLE_INVENTORY_LOCATION} && \
    chown -R ${ORACLE_USER}:${ORACLE_INSTALL_GROUP} ${ORACLE_ROOT}

# Setup who file
ADD who /usr/bin/
RUN chmod 755 /usr/bin/who

# Set working directory
WORKDIR ${ORACLE_USER_HOME}

# Prepare install script
ADD install.sh .
RUN chmod a+x install.sh

# Run install script
USER oracle
RUN ./install.sh

# Run post-install script
USER root
RUN ${ORACLE_HOME}/root.sh

# Prepare .bashrc and sql scripts
ADD .bashrc .
ADD sql/* sql/

# Prepare run script
ADD run.sh .
RUN chown -R ${ORACLE_USER}:${ORACLE_INSTALL_GROUP} run.sh && \
    chmod a+x run.sh

# Create shared folder
ENV ORACLE_DB_FOLDER=/oracle/shared
RUN mkdir -p ${ORACLE_DB_FOLDER} && \
    chown -R ${ORACLE_USER}:${ORACLE_INSTALL_GROUP} ${ORACLE_DB_FOLDER}

# Run options
USER oracle
EXPOSE 1521 22
CMD bash -l -c "${ORACLE_USER_HOME}/run.sh"
VOLUME ${ORACLE_DB_FOLDER}
