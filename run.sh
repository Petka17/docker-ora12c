#!/bin/bash
set -e
set -o pipefail

function startupdb {
  echo "*** Starting database $ORACLE_SID"
  sqlplus / as sysdba @${ORACLE_USER_HOME}/sql/startup.sql
}

function shutdowndb {
  echo "*** Shutting down database $ORACLE_SID"
  sqlplus / as sysdba @${ORACLE_USER_HOME}/sql/shutdown.sql
}

function initdb {
  echo "ORACLE_SID: $ORACLE_SID"
  echo "SYS_PASSWORD: $SYS_PASSWORD"
  echo "ORACLE_DB_FOLDER: $ORACLE_DB_FOLDER"

  # Check if database already exists
  if [ -d ${ORACLE_DB_FOLDER}/oradata ]; then
    echo "Database already exists"
    exit 1
  else
    echo "Creating database in ${ORACLE_DB_FOLDER}"

    sed "s|{ORACLE_BASE}|$ORACLE_DB_FOLDER|g" $ORACLE_HOME/assistants/dbca/templates/General_Purpose.dbc > template.dbc

    dbca -silent \
         -responseFile $ORACLE_USER_HOME/dbca.rsp \
         -gdbname $ORACLE_SID \
         -sid $ORACLE_SID \
         -sysPassword $SYS_PASSWORD \
         -systemPassword $SYS_PASSWORD \
         -characterSet AL32UTF8 \
         -templateName $ORACLE_USER_HOME/template.dbc

    if [ $? -eq 1 ]; then
      echo "Error during db creation"
      cat $ORACLE_BASE/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log
      exit 1
    fi

    shutdowndb

    cp -r $ORACLE_HOME/dbs ${ORACLE_DB_FOLDER}/
  fi
}

function rundb {
  echo "DB_FILE_FOLDER: /oracle"
  echo "ORACLE_SID: $ORACLE_SID"

  if [ -d ${ORACLE_DB_FOLDER}/oradata ]; then
    startupdb
    lsnrctl start

    # Tail the alert log so the process will keep running
    trap "echo Caught term signal!" HUP INT QUIT KILL TERM
    tail -n 1000 -F ${ORACLE_BASE}/diag/rdbms/$ORACLE_SID/$ORACLE_SID/alert/log.xml | grep --line-buffered "<txt>" | stdbuf -o0 sed 's/ <txt>//' &
    wait || true
    lsnrctl stop
    shutdowndb
  else
    echo "Database not found"
    exit 1
  fi
}

case "$COMMAND" in
  initdb)
    initdb
    ;;
  rundb)
    rundb
    ;;
  *)
    echo "Environment variable COMMAND must be {initdb|sqlpluslocal|runsqllocal|rundb|sqlplusremote|runsqlremote}, e.g.:"
    echo "  To initialize a database SIEBELDB in /tmp/db-FOO:"
    echo "  docker run -it -e COMMAND=initdb -e SYS_PASSWORD=system -e ORACLE_SID=SIEBELDB --volumes-from dbdata ora12c"
         "  docker run -it -e COMMAND=initdb -e SYS_PASSWORD=system -e ORACLE_SID=SIEBELDB ora12c bash"

    echo "  To start the database:"
    echo "  export DB_FILE_FOLDER=/oracle/database/dbs"
    echo "  docker run -d -e COMMAND=rundb -e ORACLE_SID=SIEBELDB -e DB_FILE_FOLDER=/oracle -v $(pwd)/db-files:/oracle -P --name db1 oracle12c"
    exit 1
    ;;
esac
