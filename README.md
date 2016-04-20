10.22.114.25

dbt ora12c --build-arg DISTRIB_URL=http://10.22.114.25:8080/database .

docker run -it --name dbdata -e COMMAND=initdb -e SYS_PASSWORD=system -e ORACLE_SID=SIEBELDB -v /oracle/shared ora12c echo "Data container started"

docker run -it -e COMMAND=initdb -e SYS_PASSWORD=system -e ORACLE_SID=SIEBELDB --volumes-from dbdata ora12c bash
