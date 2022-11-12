FROM jupyter/scipy-notebook:python-3.9.13

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

### Install of Java ###
ENV JAVA_VERSION=8
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${JAVA_VERSION}-jre-headless" \
    ca-certificates-java && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

### Few more packkages ###
RUN apt-get update && apt-get install -y gnupg2
RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends \
      jq \
      vim \
      libkrb5-dev \
      libssl-dev \
      krb5-user \
      s3cmd \
      wget \
      curl \
      openssl \
      libnss-ldap \
      libpam-ldap \
      ldap-utils \
      bind9 \
      nginx \
      libnginx-mod-stream \
      cron \
      dnsutils \
      telnet \
      netcat \
      curl \
      nmap \
      net-tools \
      iputils-ping \
      wget \
      mlocate \
    && rm -rf /var/lib/apt/lists/*

### Install of Spark ###
ENV APACHE_SPARK_VERSION 2.3.5
ENV HADOOP_VERSION 3.1.1
WORKDIR /var/tmp
COPY files/spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp.tgz /var/tmp
RUN tar xvzf spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp.tgz -C /usr/local --owner root --group root --no-same-owner && \
    rm spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp.tgz && \
    mv /usr/local/spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp /usr/local/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

WORKDIR /usr/local

### Configuration of Spark ###
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin"

RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark && \
    # Add a link in the before_notebook hook in order to source automatically PYTHONPATH
    mkdir -p /usr/local/bin/before-notebook.d && \
    ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Fix Spark installation for Java 11 and Apache Arrow library
# see: https://github.com/apache/spark/pull/27356, https://spark.apache.org/docs/latest/#downloading
#RUN cp -p "${SPARK_HOME}/conf/spark-defaults.conf.template" "${SPARK_HOME}/conf/spark-defaults.conf" && \
#    echo 'spark.driver.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
#    echo 'spark.executor.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf"

# Configure IPython system-wide
COPY files/ipython_kernel_config.py "/etc/ipython/"
RUN fix-permissions "/etc/ipython/"

######### RSpark not in TDP for the moment #########
# RSpark config
#ENV R_LIBS_USER "${SPARK_HOME}/R/lib"
#RUN fix-permissions "${R_LIBS_USER}"

# R pre-requisites
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

### Configuration of Nginx ###
RUN mkdir -p /var/lib/nginx && \
  mkdir -p /etc/nginx/sites-enabled && \
  mkdir -p /etc/nginx/certs && \
  mkdir -p /etc/nginx/conf.d && \
  mkdir -p /var/log/nginx && \
  mkdir -p /var/www/html && \
  mkdir -p /var/tmp/logs && \
  mkdir -p /var/tmp/run && \
  mkdir -p /data/www/html && \
  mkdir -p /var/www/localhost/htdocs && \
  mkdir -p /etc/ssl/private && \
  mkdir -p /etc/ssl/certs && \
  echo "<h1>Hello world!</h1>" > /var/www/localhost/htdocs/index.html;

RUN openssl req -x509 -nodes -days 3650 \
-subj "/C=CA/ST=QC/O=Company, Inc./CN=mydomain.com" \
-newkey rsa:2048 \
-keyout /etc/ssl/private/nginx-selfsigned.key \
-out /etc/ssl/certs/nginx-selfsigned.crt;

ADD files/nginx.conf /etc/nginx/nginx.conf
ADD files/myapp.conf /etc/nginx/conf.d/myapp.conf
ADD files/tdp_user.htpasswd /etc/nginx/conf.d/tdp_user.htpasswd

### Quick Fix for Nginx running with user jovyan ###

RUN chown -R jovyan:users /etc/nginx \
  && chown -R jovyan:users /var/log/nginx \
  && chown -R jovyan:users /var/lib/nginx \
  && chown -R jovyan:users /etc/ssl/certs \
  && chown -R jovyan:users /etc/ssl/private \
  && chmod 777 /var/tmp \
  && chmod 777 /var/tmp/* \
  && mkdir /etc/krb5.conf.d

### Dumb init ###
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
    echo "37f2c1f0372a45554f1b89924fbb134fc24c3756efaedf11e07f599494e0eff9  /usr/local/bin/dumb-init" | sha256sum -c - && \
    chmod 755 /usr/local/bin/dumb-init

CMD ["start-notebook.sh"]

COPY files/start-notebook.sh /usr/local/bin/start-notebook.sh
RUN chmod +x /usr/local/bin/start-notebook.sh
COPY files/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

######### Change user from Root to Jupyter User #########
USER ${NB_UID}

# R packages including IRKernel which gets installed globally.
# RUN mamba install --quiet --yes \
#     'r-base' \
#     'r-ggplot2' \
#     'r-irkernel' \
#     'r-rcurl' \
#     'r-sparklyr' && \
#     mamba clean --all -f -y && \
#     fix-permissions "${CONDA_DIR}" && \
#     fix-permissions "/home/${NB_USER}"

# Install Fat requirements
COPY files/fat_requirements.txt /fat_requirements.txt
RUN mamba install --quiet --yes --file /fat_requirements.txt && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Spylon-kernel
RUN mamba install --quiet --yes 'spylon-kernel' && \
    mamba clean --all -f -y && \
    python -m spylon_kernel install --sys-prefix && \
    rm -rf "/home/${NB_USER}/.local" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

######### Change user back to root #########
USER root
# Configuration of Sparkmagic
RUN cd /opt/conda/lib/python3.9/site-packages \
  && jupyter nbextension enable --py --sys-prefix widgetsnbextension \
  && jupyter labextension install @jupyter-widgets/jupyterlab-manager \
  && jupyter-kernelspec install --name Sparkmagic sparkmagic/kernels/sparkkernel \
#  && jupyter-kernelspec install --name SparkRmagic sparkmagic/kernels/sparkrkernel \
  && jupyter-kernelspec install --name PySparkmagic sparkmagic/kernels/pysparkkernel

RUN chown -R jovyan:users /home/jovyan \
  && pip3 list

### Add TDP sandbox confs ###
COPY files/hosts /etc/hosts
COPY files/krb5.conf /etc/krb5.conf
COPY files/clients-config.tar.gz clients-config.tar.gz 
COPY files/start.me.up.before.you.go.go.sh /home/jovyan/start.me.up.before.you.go.go.sh
COPY files/sparkmagic.kernel.json /usr/local/share/jupyter/kernels/sparkmagic/kernel.json
#COPY files/sparkrmagic.kernel.json /usr/local/share/jupyter/kernels/sparkrmagic/kernel.json
COPY files/pysparkmagic.kernel.json /usr/local/share/jupyter/kernels/pysparkmagic/kernel.json

### Add TDP clients confs ###
RUN  mkdir -p clients-config && \
  tar -xzf clients-config.tar.gz -C clients-config && \
  mkdir -p /etc/cluster/hadoop && rm -rf /etc/cluster/hadoop/* && \
  mkdir -p /etc/cluster/hive && rm -rf /etc/cluster/hive/* && \
  mkdir -p /usr/local/spark/${APACHE_SPARK_VERSON}/conf && rm -rf /usr/local/spark/conf/* && \
  mkdir -p /etc/cluster/hbase && rm -rf /etc/cluster/hbase/* && \
  cp -r clients-config/hadoop/* /etc/cluster/hadoop && \
  cp -r clients-config/hive/* /etc/cluster/hive && \
  cp -r clients-config/hbase/* /etc/cluster/hbase && \
  cp -r clients-config/spark/* /usr/local/spark/conf && \
  rm clients-config.tar.gz && \
  rm -rf clients-config

### Add TDP SSL confs ###
COPY files/root.pem /root.pem
RUN cat /root.pem >> /opt/conda/lib/python3.9/site-packages/certifi/cacert.pem && \
  rm /root.pem
COPY files/truststore.jks /truststore.jks
RUN mkdir -p /data
RUN mkdir -p /etc/security/keytabs/
RUN mkdir -p /etc/ssl/certs/
RUN mkdir -p /etc/security/serverKeys/
RUN cp -rf /truststore.jks /etc/ssl/certs/truststore.jks
RUN cp -rf /truststore.jks /etc/security/serverKeys/truststore
RUN mkdir -p /persisted_notebook

### Add Hadoop to profile ###
RUN echo "export HADOOP_CONF_DIR=/etc/cluster/hadoop" >> /etc/profile.d/hadoop.sh

RUN chown -R jovyan:users /persisted_notebook \
  && chown -R jovyan:users /data \
  && chown -R jovyan:users /etc/security/keytabs \
  && chown -R jovyan:users /home/jovyan

RUN touch /var/run/crontab.pid \
  && chgrp crontab /var/run/crontab.pid

RUN touch /var/run/crond.pid \
  && chgrp crontab /var/run/crond.pid

RUN usermod -a -G crontab jovyan

RUN chown root:crontab /usr/sbin/cron \
  && chmod g+s /usr/sbin/cron \
  && chmod u+s /usr/sbin/cron \
  && chown root:crontab /var/spool/cron/crontabs \
  && chmod u=rwx,g=wx,o=t /var/spool/cron/crontabs \
  && chmod -R g+s /var/spool/cron

CMD ["start-notebook.sh"]

######### Change user back to User #########
USER ${NB_UID}

WORKDIR "${HOME}"

RUN echo "*/5 * * * * cp -f -p -r /home/jovyan/. /persisted_notebook/"  >> jupytercron \
  && crontab jupytercron \
  && rm jupytercron

RUN mkdir -p /home/jovyan/.sparkmagic/ \
  && mkdir -p /home/jovyan/.jupyter/ \
  && cd

COPY files/sparkmagic.config.json /home/jovyan/.sparkmagic/config.json
COPY files/jupyter_notebook_config.py /home/jovyan/.jupyter/jupyter_notebook_config.py