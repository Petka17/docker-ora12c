#!/bin/bash
set -e

echo "Start installation..."

echo "-> Prepare oraInst.loc"
echo "inventory_loc=${ORACLE_INVENTORY_LOCATION}
inst_group=${ORACLE_INSTALL_GROUP}" > ${ORACLE_INST_LOC_FILE}
cat ${ORACLE_INST_LOC_FILE}

echo "-> Download distributives"
mkdir -p ${DISTRIB_FOLDER}
echo "Fetiching ${DISTRIB_URL}/linuxamd64_12102_database_1of2.zip"
curl -L -o ${DISTRIB_FOLDER}/linuxamd64_12102_database_1of2.zip ${DISTRIB_URL}/linuxamd64_12102_database_1of2.zip
echo "Fetiching ${DISTRIB_URL}/linuxamd64_12102_database_2of2.zip"
curl -L -o ${DISTRIB_FOLDER}/linuxamd64_12102_database_2of2.zip ${DISTRIB_URL}/linuxamd64_12102_database_2of2.zip

echo "-> Unzip archives"
unzip -q ${DISTRIB_FOLDER}/linuxamd64_12102_database_1of2.zip -d ${ORACLE_USER_HOME}
unzip -q ${DISTRIB_FOLDER}/linuxamd64_12102_database_2of2.zip -d ${ORACLE_USER_HOME}

echo "-> Run installer"
${ORACLE_USER_HOME}/database/runInstaller \
            -showProgress \
            -silent \
            -waitforcompletion \
            -ignoreSysPrereqs \
            -ignorePrereq \
            -responseFile ${ORACLE_USER_HOME}/database/response/db_install.rsp \
            -invPtrLoc ${ORACLE_INST_LOC_FILE} \
            oracle.install.option=INSTALL_DB_SWONLY \
            ORACLE_BASE=${ORACLE_BASE} \
            ORACLE_HOME=${ORACLE_HOME} \
            INVENTORY_LOCATION=${ORACLE_INVENTORY_LOCATION} \
            UNIX_GROUP_NAME=${ORACLE_INSTALL_GROUP} \
            oracle.install.db.DBA_GROUP=${ORACLE_DBA_GROUP} \
            oracle.install.db.OPER_GROUP=${ORACLE_DBA_GROUP} \
            oracle.install.db.BACKUPDBA_GROUP=${ORACLE_DBA_GROUP} \
            oracle.install.db.DGDBA_GROUP=${ORACLE_DBA_GROUP} \
            oracle.install.db.KMDBA_GROUP=${ORACLE_DBA_GROUP} \
            SELECTED_LANGUAGES=en \
            oracle.install.db.InstallEdition=EE \
            oracle.install.db.EEOptionsSelection=false \
            oracle.install.db.isRACOneInstall=false \
            DECLINE_SECURITY_UPDATES=true \
            SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
            oracle.installer.autoupdates.option=SKIP_UPDATES

echo "->Copy dbca response file"
cp ${ORACLE_USER_HOME}/database/response/dbca.rsp ${ORACLE_USER_HOME}/

echo "-> Remove distributives"
rm -fr ${ORACLE_USER_HOME}/database;
rm -fr ${DISTRIB_FOLDER};

echo "-> Commiting layer"
