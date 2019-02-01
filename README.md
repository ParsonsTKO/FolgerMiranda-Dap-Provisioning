# Infrastructure for Folger created with Terraform

This is the infrastructure as code provided by Terraform. Please read the documentation of Terraform in https://www.terraform.io/docs/index.html

## Software requirements

### Install requirements

```bash
make requirements
```

## Unlock sensitive data

Terraform creates some files with sensitive data that needs to be encrypted, specially the infrastucture state (`terraform.tfstate`). The encryption is done using a GPG key. In order to unlock the files you need to create a GPG key and ask the owner of the repo to include your key in the repo.

[Git Crypt](https://www.agwa.name/projects/git-crypt/) is used to transparently manage the encryption and decryption of files in the git repository. Protected files are encrypted when committed, and decrypted when checked out.

### Generate the GPG key pair

```bash
gpg --full-generate-key
```

### Export public GPG key

Look for your Key ID in using the following command:

```bash
gpg --list-secret-keys --keyid-format LONG
```

Use the Key ID to get the Publick Key:

```bash
gpg --armor --export <GPG key ID>
```

Send the public GPG key to the owner of the repo to be added to the trusted collaborators.

### Export private GPG key

If you need to export your private GPG key (to move to a different machine), use the following command:

```bash
gpg --export-secret-keys -a <GPG key ID>
```

### Add a new colaborator

To add a colaborator GPG public key you need first to import the key into your local key chain:

```bash
gpg --import gpg_public.key
```

See the ID of the new added key:

```bash
gpg --list-keys
```

Then add the key ID to the git crypt users

```bash
git-crypt add-gpg-user --trusted <GPG key ID>
```

Git crypt automatically commit the new key, so you only need to push the changes to the remote repo.

## Install the configuration

Once the key is added execute the following command:

```bash
make install
```

## Configure AWS credentials

In order to create or modify infrastructure resources you will need an AWS credentials with enough permission to create or modify resources in the AWS account. You need to create the file `.env` and add your AWS Access and Secret keys, you can use the `.env.dist` file as example.

> Never commit AWS credentials to version control (Git), make sure that the AWS credentials and other sensitive data are placed only in the `.env` file which is ignored in the version control.

## Working with Terraform configuration

Terraform is a tool to manage infrastructure as code. All the resources of the infrastructure are managed by Terraform in the configuration files. To know more about Terraform configuration please visit https://www.terraform.io

### Planning the infrastructure

Terraform allows to preview the changes to the infrastructure resources before they are actually created or changed, to do so use the following command:

```bash
make plan
```

You will see a list of resources and its configurations, along with the changes that will be performed. Terraform displays the changes to deploy in a colored fashion and using prefixes similar to the Git differences

-   Resources in green and with `+` prefix will be created.
-   Resource in yellow and with `~` prefix will be modified in place.
-   Resource in yellow and with `-/+` prefix will be recreated (destroy then create).
-   Resources in red with `-` prefix will be destroyed.

### Deploying the infrastructure

In order to actually deploy the changes execute the following command:

```bash
make apply
```

Terraform will display again the changes to be performed and ask for confirmation.

### Displaying the infrastructure resources

In order to see all the resources managed by Terraform execute the following command:

```bash
make show
```

Terraform will display a detailed list of all resources managed by the configuration.

### Destroying the infrastructure

In order to remove all resources execute the following command:

```bash
make destroy
```

Terraform will ask for confirmation.

> This command will destroy all the resources managed by the Terraform configuration. This is only recommended during testing or for with ephemeral resources.

## Making changes to the infrastructure

It is possible to modify the internal configuration of the infrastructure resources using the Terraform configuration files. All the changes to the configuration files should be added to version control in order to keep track and consistency of the changes.

### Changing global parameters

Use the `main.tf` file to configure the global parameters of the infrastructure, e.g. Name of the website, environment, number of Availability Zones or AWS region where the resources will be deployed.

### Changing resources

-   Common resources: `common.tf`
-   Staging resources: `staging.tf`
-   Production resources: `production.tf`

### Changing sensitive parameters

Use the `secrets.tf` file to add sensitive configurations, e.g. Database passwords, user credentials, tokens, etc. This file will be automatically encrypted with the GPG key when added to the version control in the same way it is done with the Terraform state file.

### Deploying ECS Services

You can find the configuration of the services in the `services.tf` file, the re is a resource for every service in the system, if you want to update the docker images version (`web-version` and `app-version` variables) of the containers running for that service. The task definition of the service is in a JSON file in the folder `files/ecs/folgerdap`. Execute the following command to deploy a specific service to the ECS.

```bash
make deploy service=<service_name>
```

Replace the `<service_name>` for one of the following services currently available:

-   `client`
-   `server`
-   `iiif`
-   `importrecords`
-   `assetsretrieval`
-   `stagingserver`
-   `stagingclient`
-   `stagingiiif`
-   `stagingassetsretrieval`
-   `stagingimportrecords`
