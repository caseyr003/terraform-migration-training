# Terraform-Migration-Training

## This Terraform script creates a user, adds the user to a group, creates two compartments, creates policies to give the user access to each compartment. It then, in one compartment, provisions a virtual cloud network, provisions a compute instance, runs a script to configure the server. Number of users needed is set dynamically in the count variable.

# Software Requirements

To run this you must have installed the Terraform binary (at least 0.9.x) and configured it per instruction.

You must also have installed the Oracle Cloud Infrastructure Terraform provider.

You will also, of course, need access to an Oracle Cloud Infrastructure (OCI) account. If you do not have access, you can request a free trial. To learn more about Oracle OCI, read the Getting Started guide.


# Environment Requirements

Please follow all instructions for installing the Terraform and Oracle Cloud Infrastructure Provider executables.

https://github.com/oracle/terraform-provider-oci


# Running

The env.sh file needs to be updated with your tenancy specific information. You can specify the number of users that will need to have an environment configured for the training by updating the "count" variable. To find more information on where to find the needed values please visit: https://docs.us-phoenix-1.oraclecloud.com/Content/API/Concepts/apisigningkey.htm

The config.sh in the "userdata" folder is used to configure the compute instance. You can supply your own script by adding it to the "userdata" folder and updating the "file" and "remote-exec" provisioners to run the new script on the instance.

Once you understand the code, have all the software requirements, and have satisfied the environmental requirements you can build your environment.

The first step is to initialize the project by typing `terraform init`. This will build out a .terraform directory in your project root. This needs to be done only once.

The next step is to run `terraform plan` from the command line to generate an execution plan. Examine this plan to see what will be built and that there are no errors.

If you are satisfied, you can build the configuration by typing `terraform apply`. This will build all of the dependencies and construct an environment to match the project.

Note that Terraform generates a terraform.tfstate and terraform.tfstate.backup file which manage the state of your environment. These files should not be hand edited.

If you want to tear down your environment, you can do that by running `terraform destroy`.

Commands:

[opc@terraform demo]$	terraform init

[opc@terraform demo]$	. ./env.sh

[opc@terraform demo]$	terraform plan

[opc@terraform demo]$	terraform apply

[opc@terraform demo]$	terraform destroy
