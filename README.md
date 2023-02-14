# run_cortx
A bash-script framework to automate CORTX setup and run on a single node VM

# Pre-requisites
* VM running Rocky 8.4 (minimal setup)

# Usage
./prep_node.sh **rocky01**
## Does the following:
* Enables password-less ssh to the VM
* Sets its hostname to ${node_name}
* Sets up CORTX preambles and dependencies
* Installs **cortx-pyutils**, **cortx-motr** and **cortx-motr-devel** from last_successful builds from Seagate CORTX github rpms
* Compiles and installs **cortx-hare**
* Creates loop devices for CORTX data
* Creates sample CDF.yaml file for cortx-hare single node cluster
* Starts CORTX single-node cluster and displays "hctl status"