#!/usr/bin/bash

set -x

export SSHPASS="a1"
export node_name=$1
export CDF_node_name="localhost"
export nw_iface=ens3
install_script="install_cortx.sh"
loop_dev_script="create_loop_devs.sh"

function usage()
{
        if [ $# -eq 0 ]
        then
                echo "Usage: No hostname specified!"
                exit
        fi
}

function replace_vars ()
{
  perl -e 'while (<STDIN>) { foreach $key (keys %ENV) { s/[#][{]${key}[}]/$ENV{$key}/g; } print; }'
}

function send_and_exec_script()
{
	script_name=$1
	node_name=$2

	scp -r scripts/${script_name} ${node_name}:~/.
	ssh ${node_name} "chmod +x ${script_name}"
	ssh ${node_name} "./${script_name}"
}

usage $1

sshpass -e ssh-copy-id root@${node_name}
ssh ${node_name} "hostnamectl set-hostname ${node_name}"

send_and_exec_script ${install_script} ${node_name}
send_and_exec_script ${loop_dev_script} ${node_name}

replace_vars < ./templates/CDF.yaml.in > ./CDF.yaml
scp ./CDF.yaml ${node_name}:~/.

ssh ${node_name} "hctl bootstrap --mkfs ~/CDF.yaml"
ssh ${node_name} "hctl status"
