### Build Oracle Database 12c image
```
docker build -t ora12c --build-arg DISTRIB_URL=http://<localhost_ip_address>:8080/database .
```

### Run data-only container to store database files
```
docker run --name dbdata -e COMMAND=data ora12c
```

### Create database
```
docker run --rm -it -e COMMAND=initdb --volumes-from dbdata ora12c
```

### Run database
```
docker run -d -it -p 1521:1521 --name db -h db -e COMMAND=rundb --volumes-from dbdata ora12c
```

### Backup volume
```
docker run --rm --volumes-from dbdata -v $(pwd):/backup busybox tar cvf /backup/backup.tar /oracle/shared
```

### Restore volume
```
docker run --rm --volumes-from dbdata -v $(pwd):/backup busybox tar xvf /backup/backup.tar
```

### Connect to runnig container
```
docker exec -it db bash

sqlplus 'sys/system@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=db)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=SIEBELDB))) as sysdba'
```
