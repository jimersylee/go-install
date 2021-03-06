#!/bin/bash
# Author: Jrohy
# Github: https://github.com/Jrohy/go-install

# cancel centos alias
[[ -f /etc/redhat-release ]] && unalias -a

INSTALL_VERSION=""

PROXY_URL="https://goproxy.io"

#######color code########
RED="31m"      
GREEN="32m"  
YELLOW="33m" 
BLUE="36m"
FUCHSIA="35m"

colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

#######get params#########
while [[ $# > 0 ]];do
    KEY="$1"
    case $KEY in
        -v|--version)
        INSTALL_VERSION="$2"
        echo -e "准备安装$(colorEcho ${BLUE} $INSTALL_VERSION)版本golang..\n"
        shift
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done
#############################

ipIsConnect(){
    ping -c2 -i0.3 -W1 $1 &>/dev/null
    if [ $? -eq 0 ];then
        return 0
    else
        return 1
    fi
}

setupEnv(){
    if [[ -z `echo $GOPATH` ]];then
        GOPATH="/home/go"
        echo "GOPATH值为: `colorEcho $BLUE $GOPATH`"
        echo "export GOPATH=$GOPATH" >> /etc/profile
        echo 'export PATH=$PATH:$GOPATH/bin' >> /etc/profile
        mkdir -p $GOPATH
    fi
    if [[ -z `echo $PATH|grep /usr/local/go/bin` ]];then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    source /etc/profile
}

setupProxy(){
    ipIsConnect "golang.org"
    if [[ ! $? -eq 0 ]]; then
        [[ -z $(grep GO111MODULE ~/.bashrc) ]] && echo "export GO111MODULE=on" >> ~/.bashrc
        [[ -z $(go env|grep $PROXY_URL) ]] && go env -w GOPROXY=$PROXY_URL,direct
        colorEcho $GREEN "当前VPS为国内VPS, 成功设置goproxy代理!"
        source ~/.bashrc
    fi
}

sysArch(){
    ARCH=$(uname -m)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="linux-386"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="linux-armv6l"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="linux-arm64"
    elif [[ "$ARCH" == *"s390x"* ]]; then
        VDIS="linux-s390x"
    elif [[ "$ARCH" == "ppc64le" ]]; then
        VDIS="linux-ppc64le"
    elif [[ "$ARCH" == *"darwin"* ]]; then
        VDIS="darwin-amd64"
    elif [[ "$ARCH" == "x86_64" ]]; then
        VDIS="linux-amd64"
    fi
}

installGo(){
    if [[ -z $INSTALL_VERSION ]];then
        echo "正在获取最新版golang..."
        INSTALL_VERSION=`curl -s https://github.com/golang/go/releases|grep releases/tag|sed '/beta/d'|sed '/rc/d'|grep -o "[0-9].*[0-9]"|head -n 1`
        echo "最新版golang: `colorEcho $BLUE $INSTALL_VERSION`"
    fi
    FILE_NAME="go${INSTALL_VERSION}.$VDIS.tar.gz"
    curl -L https://dl.google.com/go/$FILE_NAME -o $FILE_NAME
    [[ -e /usr/local/go ]] && rm -rf /usr/local/go
    tar -C /usr/local -xzf $FILE_NAME
    rm -f $FILE_NAME
}

main(){
    sysArch
    installGo
    setupEnv
    setupProxy
    echo -e "golang `colorEcho $BLUE $INSTALL_VERSION` 安装成功!"
}

main
