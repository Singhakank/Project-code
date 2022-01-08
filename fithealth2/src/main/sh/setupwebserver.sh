#!/bin/bash
IS_JDK11_INSTALLED=0
IS_TOMCAT_INSTALLED=0
IS_TOMCAT_SERVICE_CONFIGURED=0

function checkJdkInstalled() {
    local JDK11_INSTALL_STATUS=$(dpkg -s openjdk-11-jdk)
    if [[ $JDK11_INSTALL_STATUS == *"install ok installed"* ]]; then
        IS_JDK11_INSTALLED=1        
    fi
}

function installJdk() {
    sudo apt install -y openjdk-11-jdk
    local JDK11_STATUS=$?
    return $JDK11_STATUS
}

function checkTomcatInstalled() {
    if [ -d $HOME/middleware/apache-tomcat-10.0.14/ ]; then
        IS_TOMCAT_INSTALLED=1
    fi
}

function installTomcat() {
    mkdir -p $HOME/middleware
    cd $HOME/middleware
    wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.0.14/bin/apache-tomcat-10.0.14.tar.gz
    gunzip apache-tomcat-10.0.14.tar.gz
    tar -xvf apache-tomcat-10.0.14.tar
    rm apache-tomcat-10.0.14.tar
    local TOMCAT_INSTALL_STATUS=$?
    return $TOMCAT_INSTALL_STATUS
}

function checkTomcatService() {
    sudo systemctl status tomcat
    local CHECK_TOMCAT_SERVICE_STATUS=$?
    if [ $CHECK_TOMCAT_SERVICE_STATUS -eq 0 ]; then
        IS_TOMCAT_SERVICE_CONFIGURED=1
    else 
        IS_TOMCAT_SERVICE_CONFIGURED=0    
    fi
}

function configureTomcatService() {
    sed -i "s|#HOME|${HOME}|g" /tmp/tomcat.service.conf
    sudo cp /tmp/tomcat.service.conf /etc/systemd/system/tomcat.service
    sudo systemctl daemon-reload
    sudo systemctl start tomcat
    local TOMCAT_SERVICE_STATUS=$?
    return $TOMCAT_SERVICE_STATUS
}

#main block
sudo apt update -y

# jdk installation section
checkJdkInstalled
if [ $IS_JDK11_INSTALLED -eq 0 ]; then
    echo "INFO:jdk11 is not available, installing jdk11..."
    installJdk
    INSTALL_JDK_STATUS=$?
    if [ $INSTALL_JDK_STATUS -eq 0 ]; then
        echo "INFO: jdk11 installation is successful"
    else
        echo "ERROR: while installing jdk11, please check the logs and retry"        
        exit 100
    fi

else
    echo "INFO: jdk11 is already installed, so skipping..."
fi

# tomcat server installation section
checkTomcatInstalled
if [ $IS_TOMCAT_INSTALLED -eq 0 ]; then
    echo "INFO: tomcat server is not installed, so installing..."
    installTomcat
    INSTALL_TOMCAT_STATUS=$?
    if [ $INSTALL_TOMCAT_STATUS -eq 0 ]; then
        echo "INFO: tomcat server installed successfully..."
    else
        echo "ERROR: failed during setting up the tomcat server, please check logs"
        exit 101
    fi
else
    echo "INFO: tomcat server is already installed, so skipping..."    
fi

checkTomcatService
if [ $IS_TOMCAT_SERVICE_CONFIGURED -eq 0 ]; then
    echo "INFO: tomcat service is not configured, proceeding to configure..."
    configureTomcatService
    CONFIGURE_TOMCAT_SERVICE_STATUS=$?
    if [ $CONFIGURE_TOMCAT_SERVICE_STATUS -eq 0 ]; then
        echo "INFO: tomcat server configured as service successfully..."
    else
        echo "ERROR: failed during configuring tomcat as a service, please check the logs"    
        exit 102
    fi
else
    echo "INFO: tomcat service is already available"    
fi
