#!/bin/bash
source /tmp/expect-mysql-secure-install.sh

IS_MYSQL_INSTALLED=0
function checkMySqlServerInstall() {
    MYSQL_STATUS=$(dpkg -s mysql-server-8.0)
    if [[ $MYSQL_STATUS == *"install ok installed"* ]]; then
        IS_MYSQL_INSTALLED=1
    fi
}

function checkAndInstallDebConfUtils() {
    DEBCONF_STATUS=$(dpkg -s debconf-utils)
    if [[ $DEBCONF_STATUS == *"install ok installed"* ]]; then
        echo "INFO: debconf-utils package is already installed, so skipping..."
    else    
        echo "INFO: debconf-utils is not found, so installing..."        
        sudo apt install -y debconf-utils
    fi
}

function checkExpectAndInstall() {
    EXPECT_STATUS=$(dpkg -s expect)
    if [[ $EXPECT_STATUS == *"install ok installed"* ]]; then
        echo "INFO: expect is already installed, so skipping.."
    else
        echo "INFO: install expect package"  
        sudo apt install -y expect
    fi
}

function installMySqlServer() {
    checkAndInstallDebConfUtils
    echo "mysql-server-8.0 mysql-server/root_password password root" | sudo debconf-set-selections
    echo "mysql-server-8.0 mysql-server/root_password_again password root" | sudo debconf-set-selections
    export DEBAIN_FRONTEND="noninteractive"    
    sudo apt install -y mysql-server-8.0
    local MYSQL_INSTALLATION_STATUS=$?
    return $MYSQL_INSTALLATION_STATUS
}

#main program
sudo apt update -y
checkMySqlServerInstall
if [ $IS_MYSQL_INSTALLED -eq 0 ]; then
    echo "INFO: mysql server 8.0 not found, installing..."
    installMySqlServer
    MYSQL_INSTALL_STATUS=$?
    if [ $MYSQL_INSTALL_STATUS -eq 0 ]; then
        checkExpectAndInstall   
        secureMySqlInstall     
    else
        echo "ERROR!: during installation of mysql server 8.0"
        exit 100
    fi
else    
    echo "INFO: mysql server 8.0 already installed, so skipping.."    
fi