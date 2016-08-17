FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install -y wget curl vim
RUN apt-get install -y software-properties-common python-setuptools libffi-dev libssl-dev python-dev  openssh-server
RUN easy_install pip
RUN pip install requests[security]
RUN pip install ansible==2.1.1.0

RUN pip install pyopenssl ndg-httpsclient pyasn1 mock six dopy xmltodict "pywinrm>=0.2.0"

RUN wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb
RUN dpkg -i vagrant_1.8.1_x86_64.deb
RUN apt-get install -y ruby ruby-dev build-essential
RUN vagrant plugin install aws vagrant-aws aws-winrm vagrant-aws-winrm vagrant-winrm-syncedfolders

ADD . /yv-at-pytn.ru
RUN rm -rf /yv-at-pytn.ru/.vagrant
RUN rm -rf /yv-at-pytn.ru/Vagrantfile
RUN chmod +x /yv-at-pytn.ru/run.sh
RUN chmod 0600 /yv-at-pytn.ru/my.pem
CMD /yv-at-pytn.ru/run.sh
