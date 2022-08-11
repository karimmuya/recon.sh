#!/usr/bin/bash
# Bug Bounty Automation - Tools installation

read -n1 -p "Install Tools? [y,n] (Recommended on Ubuntu 20.04.4 LTS) " doit
case $doit in
y | Y)
    echo -e "\n\n\n[+] RELAX, INSTALLING TOOLSSS ...\n\n\n"
    apt update
    apt install nmap -y
    snap install amass
    apt install unzip -y
    apt install python3-pip -y

    wget https://dl.google.com/go/go1.17.7.linux-amd64.tar.gz
    tar -xvf go1.17.7.linux-amd64.tar.gz
    mv go /usr/local
    echo "export GOROOT=/usr/local/go" >>~/.profile
    echo "export GOPATH=\$HOME/go" >>~/.profile
    echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >>~/.profile
    echo "export GO111MODULE=on" >>~/.profile
    source ~/.profile
    rm go1.17.7.linux-amd64.tar.gz

    go install -v github.com/tomnomnom/httprobe@master
    go install -v github.com/ffuf/ffuf@latest
    go install -v github.com/michenriksen/aquatone@latest
    go install -v github.com/tomnomnom/waybackurls@latest
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    go install -v github.com/tomnomnom/gf@latest
    go install -v github.com/lc/gau/v2/cmd/gau@latest
    go install -v github.com/tomnomnom/qsreplace@latest
    go install -v github.com/jaeles-project/gospider@latest

    git clone https://github.com/maurosoria/dirsearch.git /opt/dirsearch
    git clone https://github.com/tomnomnom/gf.git /opt/gf
    git clone https://github.com/1ndianl33t/Gf-Patterns /opt/Gf-Patterns
    git clone https://github.com/ghostsec420/JexBotv4.git /opt/jex
    mkdir ~/.gf
    mv /opt/Gf-Patterns/*.json ~/.gf
    mv /opt/gf/examples/*json ~/.gf
    rm -rf /opt/gf
    rm -rf /opt/Gf-Patterns
    pip install -r /opt/dirsearch/requirements.txt
    pip install git-dumper

    add-apt-repository ppa:saiarcot895/chromium-beta
    apt-get update -y
    apt-get install chromium-browser -y
    wget https://github.com/michenriksen/aquatone/releases/download/v1.4.3/aquatone_linux_amd64_1.4.3.zip
    unzip aquatone_linux_amd64_1.4.3.zip
    mv aquatone /usr/local/bin/
    rm -rf aquatone_linux_amd64_1.4.3.zip LICENSE.txt README.md

    mkdir -p /opt/wordlists
    wget https://raw.githubusercontent.com/maurosoria/dirsearch/master/db/dicc.txt -O /opt/wordlists/dicc.txt
    wget https://raw.githubusercontent.com/daviddias/node-dirbuster/master/lists/directory-list-2.3-medium.txt -O /opt/wordlists/directory-list-2.3-medium.txt

    ;;

n | N) echo -e "\n\n\nStarting...\n\n\n" ;;
*) exit 0 ;;
esac
