#!/bin/bash

# Reset
Reset='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

function title {
  printf "\n\n${BCyan}  ***${UYellow} $@ ${BCyan}***${Reset}\n\n"
}

function info {
  printf "\n\n${BBlue}  ***${BCyan} $@ ${BBlue}***${Reset}\n\n"
}

title "Provision"

info "Update"
sudo apt update -y
sudo apt upgrade -y

info "Install basic tools and sources"
sudo apt install -y gnupg curl git make unzip apt-transport-https bash-completion
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main" | sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list
curl -Ls https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo add-apt-repository -y ppa:jonathonf/vim
sudo apt update -y

info "Install jq and k8s tools"
sudo apt install -y jq helm tektoncd-cli vim

info "Install oh my bash"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

info "Install docker in experimental mode"
# We don't have to restart the daemon here because we don't use experimental mode in this provisioner
sudo curl -sL get.docker.com | sh
sudo usermod -aG docker ubuntu
sudo docker pull rancher/k3d-proxy
sudo chmod a+rwx /etc
sudo chmod a+rwx /etc/docker
touch /etc/docker/daemon.json
sudo chmod a+rwx /etc/docker/daemon.json
cat <<EOF >> /etc/docker/daemon.json
{
  "experimental": true
}
EOF

info "Install k3d and kubectl"
curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
curl -LOs https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod a+rx kubectl
sudo mv kubectl /usr/local/bin
echo 'source <(kubectl completion bash)' >> ~/.bashrc
sudo kubectl completion bash > /etc/bash_completion.d/kubectl
chmod a+rw /etc/bash_completion.d/kubectl

info "Install node.js"
curl -sL install-node.now.sh/lts | sudo bash -s -- -f

info "Fix vim"
mkdir -p /home/ubuntu/.config/coc
git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform
git clone https://github.com/hashivim/vim-packer.git ~/.vim/pack/plugins/start/vim-packer
git clone https://github.com/tpope/vim-fugitive.git ~/.vim/pack/plugins/start/fugitive
git clone https://github.com/martinda/Jenkinsfile-vim-syntax.git ~/.vim/pack/plugins/start/jenkinsfile
git clone -b release https://github.com/neoclide/coc.nvim.git ~/.vim/pack/plugins/start/coc.nvim

cat <<EOF >> /home/ubuntu/.vimrc
" add yaml stuffs
au! BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml foldmethod=indent
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
EOF

info "Create aliases"
echo 'alias v=vault' > /home/ubuntu/.bash_aliases
echo 'alias k=kubectl' > /home/ubuntu/.bash_aliases
echo 'alias kk=krew' >> /home/ubuntu/.bash_aliases
echo 'alias t=tkn' >> /home/ubuntu/.bash_aliases
echo "alias ll='ls -gAlFh'" >> /home/ubuntu/.bash_aliases
echo "source /home/ubuntu/.bash_aliases" >> .bashrc

info "Install Krew"
tmp=$(mktemp -d)
cd $tmp
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz"
tar zxf krew.tar.gz
./krew-linux_amd64 install krew
cd /home/ubuntu
rm -rf $tmp
PATH=$PATH:/home/ubuntu/.krew/bin

info "Install vault client"
curl -sO https://releases.hashicorp.com/vault/1.5.4/vault_1.5.4_linux_amd64.zip
unzip vault_1.5.4_linux_amd64.zip
sudo chmod a+rx vault
sudo mv vault /usr/local/bin
rm vault_*.zip

info "Tidy"
sudo apt autoremove -y
rm -f /home/ubuntu/provision.sh

cd /home/ubuntu
mkdir -p git
cd git
git clone https://github.com/KnowledgeHut-AWS/k8s-sandbox
rm -f provision.sh
title "done"
