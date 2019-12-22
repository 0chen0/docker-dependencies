FROM ubuntu:16.04
COPY ./docker-cache/apt-source/ali.sources.list /etc/apt/
RUN cp /etc/apt/sources.list /etc/apt/bak.sources.list

# 安装必要的工具
RUN	cat /etc/apt/ali.sources.list > /etc/apt/sources.list && apt-get update \
	&& apt-get install -y zip dpkg-dev

#### 将要缓存的安装包写入文件dependencies-list.txt, 分隔符为空格或换行 ####
# 这里还会要设置源
COPY ./dependencies-list.txt  /root/
RUN	cat /etc/apt/bak.sources.list > /etc/apt/sources.list \
	&& apt-get clean && apt-get update \
    && apt-get install --download-only -y `cat /root/dependencies-list.txt`

RUN mkdir /var/packages-offline \
	&& chmod 777 -R /var/packages-offline/ \
	&& cp -r /var/cache/apt/archives /var/packages-offline
WORKDIR /var/packages-offline/
RUN dpkg-scanpackages . /dev/null | gzip >/var/packages-offline/Packages.gz \
	&& mv /var/packages-offline/Packages.gz /var/packages-offline/archives/Packages.gz \
	&& mv /root/dependencies-list.txt /var/packages-offline/ \
	&& zip -r /var/docker-dependencies.zip /var/packages-offline/

# 这两行只是为了模拟另一台机器的环境
WORKDIR /
RUN rm -rf /var/packages-offline/

#### 这部分是安装缓存好的包. 另一个环境 ####
# COPY ./docker-cache/docker-dependencies.zip /var/docker-dependencies.zip
RUN	cat /etc/apt/ali.sources.list > /etc/apt/sources.list && apt-get update \
	&& apt-get install -y unzip
RUN unzip /var/docker-dependencies.zip -d / \
	&& printf "deb file:///var/packages-offline archives/\n" > /etc/apt/sources.list \
	&& apt-get update && apt-get install -y --allow-unauthenticated `cat /var/packages-offline/dependencies-list.txt`

#### 这里直接复制到指定路径 ####
# CMD cp /var/docker-dependencies.zip /docker-share/muduo-docker/.devcontainer/docker-cache/muduo-dependencies.zip
