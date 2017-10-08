#!/bin/bash

### Color Variables
Y="\e[33m"
R="\e[31m"
G="\e[32m"
B="\e[34m"
C="\e[36m"
N="\e[0m"

### Variables
URL="http://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.1/bin/apache-tomcat-9.0.1.tar.gz"
TAR_FILE_NAME=$(echo $URL |awk -F / '{print $NF}')
TAR_DIR=$(echo $TAR_FILE_NAME|sed -e 's/.tar.gz//')
### Root user check
ID=`id -u`
if [ $ID -ne 0 ]; then
	echo -e "$R You should be root user to perform this command $N"
	echo -e "$Y If you have sudo access then run the script with sudo command $N"
	exit 1
fi
#### Installation of WEb Server
echo -n -e "$Y Installing Web Server..$N"
yum install httpd httpd-devel -y &>/dev/null
if [ $? -eq 0 ]; then
	echo -e "$G SUCCESS $N"
else
	echo -e "$R FAILURE $N"
fi


### Tomcat Instaallation
echo -n -e "$Y Downloading Tomcat .. $N"
wget $URL -O /tmp/$TAR_FILE_NAME &>/dev/null
tar tf /tmp/$TAR_FILE_NAME &>/dev/null
if [ $? -eq 0 ]; then
        echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

if [ -d /opt/tomcat ]; then 
	rm -rf /opt/tomcat
fi

echo -n -e "$Y Extracting Tomcat .. $N"
cd /opt
tar xf /tmp/$TAR_FILE_NAME 
mv $TAR_DIR tomcat
if [ -d /opt/tomcat ]; then 
	echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

### DB Installation
echo -n -e "$Y Installing Database .. $N"
yum install mariadb mariadb-server -y &>/dev/null
if [ $? -eq 0 ]; then 
        echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi

systemctl start mariadb
systemctl enable mariadb &>/dev/null

#### Setting up DB 
echo -n -e "$B Configuring DB .. $N"
mysql -e 'use studentapp' &>/dev/null
if [ $? -eq 0 ]; then 
	echo -e "$C Skipping $N"
else

mysql <<EOF
create database studentapp;
use studentapp;
CREATE TABLE Students(student_id INT NOT NULL AUTO_INCREMENT,
	student_name VARCHAR(100) NOT NULL,
    student_addr VARCHAR(100) NOT NULL,
	student_age VARCHAR(3) NOT NULL,
	student_qual VARCHAR(20) NOT NULL,
	student_percent VARCHAR(10) NOT NULL,
	student_year_passed VARCHAR(10) NOT NULL,
	PRIMARY KEY (student_id)
);
grant all privileges on studentapp.* to 'student'@'10.128.0.5' identified by 'student@1';
EOF
echo -e "$G SUCCESS $N"
fi

### Configuring Tomcat
echo -n -e "$B Configuring Tomcat .. $N"
wget -O /opt/tomcat/lib/mysql-connector-java-5.1.40.jar https://github.com/carreerit/cogito/raw/master/appstack/mysql-connector-java-5.1.40.jar &>/dev/null
rm -rf /opt/tomcat/webapps/*
wget -O /opt/tomcat/webapps/student.war https://github.com/carreerit/cogito/raw/master/appstack/student.war &>/dev/null
sed -i -e '$ i <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxTotal="100" maxIdle="30" maxWaitMillis="10000" username="student" password="student@1" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://localhost:3306/studentapp"/>' /opt/tomcat/conf/context.xml
grep TestDB /opt/tomcat/conf/context.xml &>/dev/null
STAT=$?
if [ -f /opt/tomcat/lib/mysql-connector-java-5.1.40.jar -a -f /opt/tomcat/webapps/student.war -a $STAT -eq 0 ];then
       echo -e "$G SUCCESS $N"
else
        echo -e "$R FAILURE $N"
fi


