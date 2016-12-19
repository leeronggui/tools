#!/bin/bash
yum install -y perl
#install logtail
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install logcheck
