# GCP Proxy Setup

This guide provides instructions on how to set up HTTP proxies on Google Cloud Platform (GCP) using Terraform, Ansible, and a shell script. Follow these steps to deploy multiple proxy servers automatically.

## Prerequisites

Before you begin, ensure you have the following installed:
- `jq`
- `gcloud`
- `terraform`
- `ansible`

Make sure that:
- You have an active GCP account with billing enabled.
- You are authorized to the gcloud CLI and have a current project and a default Compute Engine region and zone set up.
- You do not exceede quota and limits based on number of proxy servers you wish to create.

## Configuration Files

You will need to provide the following configuration files:
- `.env`: Contains the proxy usernames and passwords.
- `./terraform.tfvars` (optional): Contains custom proxy server names, regions, and ports.
## Setup Instructions

1. **Clone the Repository**

   Start by cloning the repository to your local machine:

    ```sh
    git clone https://github.com/le-xyc/gcp-proxy-setup
    cd gcp-proxy-setup
    ```

2. **Configure** `.env` **File**

    Create a `.env` file in the root directory and define `PROXIES_USERNAMES` and `PROXIES_PASSWORDS` variables inside. Both should be strings of space-delimited usernames and passwords correspondingly. Make sure there is no number mismatch and each password is paired with the respective username in the order they are listed.
    ```
    PROXIES_USERNAMES="username1 username2 username3"
    PROXIES_PASSWORDS="password1 password2 password3"
    ```

3. **Configure** `terraform/terraform.tfvars` **(Optional)**

    If you want to specify custom instance names, regions, or ports, create a `terraform/terraform.tfvars` file and define `instances_names`, `regions`, or `ports` variables which are list of strings with custom values. In case of not providing values or a number mismatch the following defaults are used:
    - **Port**: `3128` (default Squid port)
    - **Region**: Taken from `gcloud` configuration
    - **Instance Names**: Generated in Terraform code (instance-1, instance-2...)

    The total count of proxy servers to be created is determined by the `.env` file.
    ```
    instances_names = ["custom-name1", "custom-name2"]
    regions = ["europe-west1", "europe-west2"]
    ports = ["3129", "8080"]
    ```

4. **Execute the** `run.sh` **Script**

    Execute the `run.sh` script from the root directory for proxy setup.
    The script will perform the following actions:
    - Check for required tools and configurations.
    - Read the .env file for proxy credentials.
    - Apply Terraform configuration to create VM instances and configure related resources.
    - Use Ansible to configure Squid Proxy on the created VM instances.
