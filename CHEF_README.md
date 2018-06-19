# Overview

This zip file starts you out with a simple example of a Chef repository that is preconfigured to work with an AWS OpsWorks Chef Automate server.
In this repository, you store cookbooks, roles, configuration files, and other artifacts for managing systems with Chef.
It is recommended that you store this repository in a version control system such as Git, and treat it like source code.



# Repository Directories

This repository contains several directories. Each directory contains a README file that describes the directory's purpose,
and how to use it for managing your systems with Chef.

* `cookbooks/` - Cookbooks that you download or create.
* `roles/` - Stores roles in .rb or .json in the repository.
* `environments/` - Stores environments in .rb or .json in the repository.



# Configuration

`.chef` is a hidden directory that contains a knife configuration file (knife.rb) and the secret authentication key (private.pem).

* .chef/knife.rb
* .chef/private.pem

The `knife.rb` file is configured so that knife operations will run against the AWS OpsWorks managed Chef Automate server.

To get started, download and install the [Chef DK](https://downloads.chef.io/chef-dk).
After installation, use the Chef `knife` utility to manage the Chef Automate server.
For more information, see the [Chef documentation for knife](https://docs.chef.io/knife.html).



# Quick-start Example
In this example, you learn how to use Chef to provision a node. The following instructions install the chef-client agent that is configured to run every 30 minutes, an Apache2 cookbook, and the Audit cookbook to run compliance checks on your node.


## Cookbooks
A cookbook is a Chef concept that defines your configurations as code. We use cookbooks to specify the desired configuration of nodes. For this example, we use three cookbooks to configure a Chef managed node with Apache2 installed, and set up continuous Chef Compliance scans.

### Chef Client Cookbook
The `chef-client` cookbook configures the Chef client agent software on each node that you connect to your Chef server. To learn more about this cookbook, see [Chef Client Cookbook](https://supermarket.chef.io/cookbooks/chef-client) in the Chef Supermarket.

### Apache2 Cookbook
The `apache2` cookbook is provided by the Chef community and can be downloaded from the [Chef Supermarket](https://supermarket.chef.io/cookbooks/apache2). It installs and configures Apache2. You can overwrite configurations and customize existing cookbooks (like Apache2) with wrapper cookbooks. An example is shown with the opsworks-audit cookbook.

### Chef Compliance with the Audit Cookbook (Optional)
To use Chef Compliance, we use the `opsworks-audit` cookbook from your site-cookbooks folder. This is a wrapper cookbook for the standard Audit cookbook from the [Chef Supermarket](https://supermarket.chef.io/cookbooks/audit). In this wrapper cookbook we specify the _DevSec SSH Baseline_ profile to be executed in our audit run. The Audit cookbook downloads the specified profiles from the server. To install your selected profiles, sign in to the Chef Automate console, and navigate to Compliance -> Profile Store -> Available. Install a profile by selecting the profile and choosing 'get' (for example, the _DevSec SSH Baseline_ profile).

OpsWorks for Chef Automate creates an admin user by default. But you can create your own user (for example, a user that manages your compliance profiles) and create new profiles for that user. For more information, see the [Chef Users](https://docs.chef.io/delivery_users_and_roles.html) webpage.  After you install profiles, they are visible in the Profiles tab. You can specify installed profiles in the opsworks-audit cookbook attributes file, so that nodes can run them as part of a compliance run.

```
site-cookbooks/opsworks-audit/attributes/default.rb
```
Example:

```
default['audit']['profiles'] = [
  {
    "name": "DevSec SSH Baseline",
    "compliance": "admin/ssh-baseline"
  }
]
```
All cookbooks are versioned in the cookbook's metadata.rb file. Each time you change a cookbook, you must raise the version of the cookbook that is in metadata.rb.

```
site-cookbooks/opsworks-audit/metadata.rb
```


## Using Berkshelf to manage your cookbooks

Berkshelf is a tool to help you manage cookbooks and their dependencies. It downloads a specified cookbook into local storage, also called the _Berkshelf_. You can specify which cookbooks and versions to use with your Chef server and upload them. This Starter Kit contains a file, named Berksfile, that references your cookbooks.

1. Use a text editor to specify your desired cookbooks in the `Berksfile`. In this example, we install the `chef-client` cookbook, the `apache2` cookbook and the `opsworks-audit` cookbook. Your Berksfile should resemble the following.

 ```
 source 'https://supermarket.chef.io'
 cookbook 'chef-client'
 cookbook 'apache2', '~> 5.0.1'
 cookbook 'opsworks-audit', path: 'site-cookbooks/opsworks-audit', '~> 1.0.0' # optional
 ```

2. Download and install the cookbooks to the cookbooks folder on your local computer.

 ```
berks vendor cookbooks
 ```

3. Upload the vendored cookbooks to your AWS OpsWorks for Chef Automate server.

 ```
knife upload .
 ```

4. Verify the installation of the cookbook by showing a list of cookbooks that are currently available on the AWS OpsWorks for Chef Automate server.

 ```
knife cookbook list
 ```


## Adding Nodes Automatically in AWS OpsWorks for Chef Automate with the prepared userdata script

To connect your first node to the AWS OpsWorks for Chef Automate server, use the **userdata.sh** script that is included in this Starter Kit. It uses the AWS OpsWorks `AssociateNode API` to connect a node to your newly created server.

To connect a node to your server, create an AWS Identity and Access Management (IAM) role to use as your EC2 instance profile. The following AWS CLI command launches an AWS CloudFormation stack that creates an IAM role for you named _myOpsWorksChefAutomateInstanceprofile_.

```
aws cloudformation --region <region> create-stack \
--stack-name myOpsWorksChefAutomateInstanceprofile \
--template-url https://s3.amazonaws.com/opsworks-cm-us-east-1-prod-default-assets/misc/opsworks-cm-nodes-roles.yaml \
--capabilities CAPABILITY_IAM
```
The userdata is ready to use. Edit the RUN_LIST setting to define which roles, cookbooks, or recipes you want to run on your new instance and upload to your server. In this example, we add "role[opsworks-example-role]" which contains three recipes (chef-client, apache2 and opsworks-audit) in your `RUN_LIST` in **userdata.sh** script.

```
RUN_LIST="role[opsworks-example-role]"
```

Alternatively you can specify each recipe individually in your `RUN_LIST`.

```
RUN_LIST="recipe[chef-client],recipe[apache2],recipe[opworks-audit]"
```

Remember those cookbooks must be uploaded to the server.


### Connect your first node

The easiest way to create a new node is to use the [Amazon EC2 Launch Wizard](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/launching-instance.html). Choose an Amazon Linux AMI. In Step 3: "Configure Instance Details", select _myOpsWorksChefAutomateInstanceprofile_ as your IAM role. In the "Advanced Details" section, upload the **userdata.sh** script.

You don't have to change anything for Step 4 and 5. Proceed to Step 6.

In Step 6, choose the appropriate rules to open ports. For example, open port numbers 443 and 80 for a web server.

Choose Review, and then choose Launch to proceed to the final Step 7. When your new node starts, it executes the `RUN_LIST` section of your **userdata.sh** script.

For more information, see the [AWS OpsWorks for Chef Automate user guide](https://docs.aws.amazon.com/opsworks/latest/userguide/opscm-unattend-assoc.html).


### Alternative: Attach an Amazon EC2 instance to the newly-launched Chef Automate server using knife bootstrap

1. Bootstrap a new Amazon EC2 instance.

 ```
 knife bootstrap <IP address of the Amazon EC2 instance>  -N <instance name> \
 -x <user name> -i <path to your ssh key file> \
 --sudo --run-list "role[opsworks-example-role]"
 ```

2. Show the new node.

 ```
knife client show <instance name>
knife node show <instance name>
 ```



## Make your first node compliant

When you follow the above example, you will see compliance violations in the Chef Automate Console's Compliance tab because the _DevSec SSH Baseline_ profile's security expectations are not yet met. The DevSec Hardening Framework(a community powered project) provides cookbooks to fix these violations.

Do the following to meet security requirements for the _DevSec SSH Baseline_ profile.

1. Using a text editor, append the `ssh-hardening` cookbook to your Berksfile. Your Berksfile should resemble the following.

 ```
source 'https://supermarket.chef.io'
cookbook 'chef-client'
cookbook 'apache2', '~> 5.0.1'
cookbook 'opsworks-audit', path: 'site-cookbooks/opsworks-audit', '~> 1.0.0' # optional
cookbook 'ssh-hardening'
 ```

2. Download the `ssh-hardening` cookbook to the cookbooks folder, and then upload it to your Opsworks for Chef Automate server.

 ```
 berks vendor cookbooks
 knife upload .
 ```
 
3. Add the `ssh-hardening` recipe to your node.
	- Add it to the role roles/opsworks-example-role.rb like in the example below. 
	  
	  ```
	  name "opsworks-example-role"
	  description "This role specifies all recipes described in the starter kit guide (README.md)"
	  
	  run_list(
  	 		"recipe[chef-client]",
  			"recipe[apache2]",
  			"recipe[opsworks-audit]",
  			"recipe[ssh-hardening]"
	  )
	  ```
	  Upload the updated role to your Chef Automate server and the node will update the role automatically.
	  
	  ```
	  knife upload .
	  ```
	- Alternatively you can add the `ssh-hardening` recipe directly to your node run list.

	  ```
	  knife node run_list add <node name> 'recipe[ssh-hardening]'
	  ```

Because you are using the `chef-client` cookbook, your node checks in at regular intervals (by default, every 30 minutes). On the next check-in, the `ssh-hardening` cookbook runs, and helps improve node security to meet the _DevSec SSH Baseline_ profile's standards.



## Learn more about Configuration Management with Chef Automate
Visit the [Learn Chef tutorial site](https://learn.chef.io/tutorials/manage-a-node/opsworks/) website to learn more about using AWS Opsworks for Chef Automate.


## Learn more about Compliance with Chef Automate
Visit the [Learn Compliance](https://learn.chef.io/tracks/integrated-compliance#/) and [Learn Compliance Automation](https://learn.chef.io/tracks/compliance-automation#/) websites to learn more about using Compliance in Chef Automate.
