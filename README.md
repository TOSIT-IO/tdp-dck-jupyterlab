# Jupyterlab 3.4.8 #

## Prerequisites ##

Get Hadoop, hive, hbase and spark2 confs (didn't include spark 3 for the moment)
```bash
cd ../tdp-getting-started
vagrant scp edge-01.tdp:/etc/hadoop/conf/* ../tdp-dck-jupyterlab/files/hadoop/
vagrant scp edge-01.tdp:/etc/hbase/conf/* ../tdp-dck-jupyterlab/files/hbase/
vagrant scp edge-01.tdp:/etc/hive/conf/* ../tdp-dck-jupyterlab/files/hive/
vagrant scp edge-01.tdp:/etc/spark/conf/* ../tdp-dck-jupyterlab/files/spark/
```
Get the hosts and kerberos files of your TDP cluster
```bash
vagrant scp edge-01.tdp:/etc/hosts ../tdp-dck-jupyterlab/files/hosts
vagrant scp edge-01.tdp:/etc/krb5.conf ../tdp-dck-jupyterlab/files/krb5.conf
vagrant scp edge-01.tdp:/home/tdp_user/tdp_user.keytab ../tdp-dck-jupyterlab/__conf-jupyterlab-3.4.8-USER/sandbox/keytabs/tdp_user.keytab
```
Create a tarball:
```bash
cd ../tdp-dck-zeppelin/files
tar cvzf clients-config.tar.gz hadoop hbase hive spark
```

## Configure Livy server ##

Add these confs:

```bash
livy.server.yarn.app-lookup-timeout=300s
livy.rsc.server.connect.timeout=200s
```

## Build this Jupyterlab Docker image ##

```bash
./build-jupyterlab-for-tdp.sh
```

## Start Jupyterlab ##

```bash
cd __conf-jupyterlab-3.4.8-USER/sandbox/
docker-compose up -d
```

## Test ##

2 working Sparkmagic kernels are already configured, one for pyspark, one for spark-scala.\
(didn't include spark 3 for the moment)\
Try this:

```bash
%%info
```

```bash
%spark
```

```bash
data = [('James','','Smith','1991-04-01','M',3000),
  ('Michael','Rose','','2000-05-19','M',4000),
  ('Robert','','Williams','1978-09-05','M',4000),
  ('Maria','Anne','Jones','1967-12-01','F',4000),
  ('Jen','Mary','Brown','1980-02-17','F',-1)
]
```

```bash
columns = ["firstname","middlename","lastname","dob","gender","salary"]
df = spark.createDataFrame(data=data, schema = columns)
```

```bash
df.show
```

## TDP connection ##

This Jupyterlab is portable, it interracts with a TDP cluster through livy, with SSL and Kerberos.

## Important Information ##

This Jupyterlab is not multi-tenant: An instance must be runned per user.

## Security choise ##

Nginx is embedded in the Docker image for SSL, for the Jupyterlab frontend.\
htpasswd is embedded in the Docker image for authentification concerns, for the Jupyterlab frontend.\
\
Then, Jupyterlab can run in Anonymous, without authentification, without SSL.\
For portability and for the use of notebooks and kernels, it is much simpler this way.

## Authentification ##

Current auth file is the following :
```bash
__conf-jupyterlab-3.4.8-USER/sandbox/conf-nginx/conf.d/tdp_user.htpasswd
```
At Runtime it ends here:
```bash
/etc/nginx/conf.d/tdp_user.htpasswd
```

## SSL ##

Self-signed certificate is generated at build-time.\
To change it, follow these steps:

```bash
cd __conf-jupyterlab-3.4.8-USER/sandbox/conf-nginx/certs/
vim nginx-selfsigned.crt 
-----BEGIN CERTIFICATE-----
...
```

```bash
cd __conf-jupyterlab-3.4.8-USER/sandbox/conf-nginx/private/
vim nginx-selfsigned.key 
-----BEGIN CERTIFICATE-----
...
```

## User Data ##

A folder is dedicated for importing/exporting files in the image at runtime
```bash
cd __conf-jupyterlab-3.4.8-USER/sandbox/data/
...
```
In the image, it will end up in /data

## Hadoop User Keytab ##

A folder is dedicated for storing the Hadoop user keytab :
```bash
cd __conf-jupyterlab-3.4.8-USER/sandbox/keytabs/
...
```
In the image, it will end up in /etc/security/keytabs

## Backups of Notebooks, Kernels and Jupyterlab confs ##

Everything is handled.\
Persisted folder is
```bash
__conf-jupyterlab-3.4.8-USER/sandbox/
```