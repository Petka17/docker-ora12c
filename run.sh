#!/bin/bash
set -e

function startupdb {
  echo "*** Starting database $ORACLE_SID"
  sqlplus / as sysdba @${ORACLE_USER_HOME}/sql/startup.sql
}

function shutdowndb {
  echo "*** Shutting down database $ORACLE_SID"
  sqlplus / as sysdba @${ORACLE_USER_HOME}/sql/shutdown.sql
}

function initdb {
  # Check if database already exists
  if [ -d ${ORACLE_DB_FOLDER}/oradata ]; then
    echo "Database already exists"
    exit 1
  fi

  echo "Creating database $ORACLE_SID in ${ORACLE_DB_FOLDER}"

  # Prepare template: replace {ORACLE_BASE} with shared folder name
  sed "s|{ORACLE_BASE}|$ORACLE_DB_FOLDER|g" $ORACLE_HOME/assistants/dbca/templates/General_Purpose.dbc > template.dbc

  # Run DB creation process
  dbca -silent \
       -responseFile $ORACLE_USER_HOME/dbca.rsp \
       -gdbname $ORACLE_SID \
       -sid $ORACLE_SID \
       -sysPassword $SYS_PASSWORD \
       -systemPassword $SYS_PASSWORD \
       -characterSet AL32UTF8 \
       -templateName $ORACLE_USER_HOME/template.dbc

  # In case of error show log
  if [ $? -eq 1 ]; then
    echo "Error during db creation"
    cat $ORACLE_BASE/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log
    exit 1
  fi

  # Stop DB
  shutdowndb

  # Move dbs folder to shared folder
  mv $ORACLE_HOME/dbs ${ORACLE_DB_FOLDER}/
}

function rundb {
  if [ ! -d ${ORACLE_DB_FOLDER}/oradata ]; then
    echo "Database not found"
    exit 1
  fi

  echo "Run database $ORACLE_SID from $ORACLE_DB_FOLDER"

  # Create sybbolic link to dbs folder
  rm -rf $ORACLE_HOME/dbs
  ln -s ${ORACLE_DB_FOLDER}/dbs $ORACLE_HOME

  # Startup database and listner
  startupdb
  lsnrctl start

  # Tail the alert log so the process will keep running
  trap "echo Caught term signal!" HUP INT QUIT KILL TERM
  tail -n 1000 -F ${ORACLE_DB_FOLDER}/diag/rdbms/${ORACLE_SID,,}/$ORACLE_SID/alert/log.xml | grep --line-buffered "<txt>" | stdbuf -o0 sed 's/ <txt>//' &
  wait || true

  # Correct stop database after get TERM signal
  lsnrctl stop
  shutdowndb
}

# Set default value for main variables
if [ -z ${SYS_PASSWORD} ]; then SYS_PASSWORD=system; fi

# We need to export ORACLE_SID in order to sqlplus to work
if [ -z ${ORACLE_SID} ]; then export ORACLE_SID=SIEBELDB; fi

# Check the command
case "$COMMAND" in
  initdb)
    initdb
    ;;
  rundb)
    rundb
    ;;
  data)
    echo "Data-only container created"
    echo "Shared folder: ${ORACLE_DB_FOLDER}"
    ;;
  *)
    echo "Environment variable COMMAND must be {initdb|rundb}"
    echo "  Run data container:"
    echo "  docker run --name dbdata -e COMMAND=data ora12c"

    echo "  To initialize a database:"
    echo "  docker run --rm -it -e COMMAND=initdb --volumes-from dbdata ora12c"

    echo "  To start the database:"
    echo "  docker run -d -p 1521:1521 --name db -e COMMAND=rundb --volumes-from dbdata ora12c"
    exit 1
    ;;
esac
