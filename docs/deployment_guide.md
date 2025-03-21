# Horizon SDV

## Overview   
Horizon SDV is designed to simplify the deployment and management of Android workloads on Google Kubernetes Engine clusters. By leveraging Infrastructure as Code (IaC) and GitOps, ensuring the cluster consistently matches the desired state, enabling scalable and efficient Android workload operations.

## Table of Contents
- [Overview](#overview)
- [Technologies](#technologies)
- [Configuration Placeholders](#configuration-placeholders)
- [Project directories and files](#project-directories-and-files)
- [Section #1 - Prerequisites](#section-1---prerequisites)
- [Section #2 - GCP Foundation Setup](#section-2---gcp-foundation-setup)
   - [Section #2a - GCP Project details](#section-2a---gcp-project-details)
   - [Section #2b - Create a Bucket in GCP](#section-2b---create-a-bucket-in-gcp)
   - [Section #2c - Create a GitHub Organization](#section-2c---create-a-github-organization)   
   - [Section #2d - Setting up GCP IAM & Admin for Terraform Workflow](#section-2d---setting-up-gcp-iam--admin-for-terraform-workflow)
   - [Section #2e - Create OAuth2 client and secret](#section-2e---create-oauth2-client-and-secret)
   - [Section #2f - Create a DNS Zone (Optional)](#section-2f---create-a-dns-zone-optional)
- [Section #3 - GitHub Foundation Setup](#section-3---github-foundation-setup)
   - [Section #3a - Setup GitHub Organization and Repository](#section-3a---setup-github-organization-and-repository)
   - [Section #3b - Create GitHub Application](#section-3b---create-github-application)
   - [Section #3c - Fork the Repository](#section-3c---fork-the-repository)
   - [Section #3d - Setup GitHub Environment](#section-3d---set-up-github-environment)
   - [Section #3e - Setup GitHub repository](#section-3e---setup-github-repository)
- [Section #4 - Trigger GitHub Actions Terraform Workflow](#section-4---trigger-github-actions-terraform-workflow)
- [Section #5 - Post Terraform Workflow Setup](#section-5---post-terraform-workflow-setup)
   - [Section #5a - Retrieve Load balancer details](#section-5a---retrieve-load-balancer-details)
   - [Section #5b - Retrieve Certificate's DNS Authz resources](#section-5b---retrieve-certificates-dns-authz-resources)
   - [Section #5c - Setup Keycloak](#section-5c---setup-keycloak)
- [Section #6 - Run Cluster Apps](#section-6---run-cluster-apps)
   - [Section #6a - Argo CD](#section-6a---argo-cd)
   - [Section #6b - Keycloak](#section-6b---keycloak)
   - [Section #6c - Gerrit](#section-6c---gerrit)
   - [Section #6d - Jenkins](#section-6d---jenkins)
   - [Section #6e - MTK connect](#section-6e---mtk-connect)
- [Section #7 - Deprovisioning Infrastructure](#section-7---deprovisioning-infrastructure)
    - [Section #7a - Install Terraform](#section-7a---install-terraform)
    - [Section #7b - Terraform Destroy](#section-7b---terraform-destroy)
- [Section #8 - Troubleshooting](#section-8---troubleshooting)
   - [Section #8a - Keycloak sign-in failure](#section-8a---keycloak-sign-in-failure)
- [LICENSE](#license)

## Technologies   
Technologies being used to provision the infrastructure along with the required applications for the GKE cluster.
* Google Cloud Platform - Cloud service provider for infrastructure provisioning.
* Terraform - IaC tool used to provision the infrastructure to maintain infrastructure consistency.
* GitHub - Source code management tool where infrastructure configuration, Kubernetes application manifests, workflows etc., are stored.
* GitHub Actions - Continuous Integration (CI) platform used for automating the deployment process.
* Argo CD - Declarative, GitOps continuous delivery tool for Kubernetes.

## Project directories and files
The project is implemented in the following directories:

+ **.github/workflows** - Consists of GitHub Action workflows directing the operation of the CI build.
+ **gitops** - Kubernetes application manifests for Argo CD, contains desired state of the cluster.
+ **terraform** - IaC configuration files to provision the infrastructure required for the GKE cluster.
+ **workloads** - Jenkins workflow scripts for the pipeline build jobs.

## Configuration Placeholders
Throughout this document, you will encounter placeholders (e.g., <GCP_PROJECT_ID>) which represent values specific to your environment.
It is required to replace them with actual values as you follow the setup instructions. Below is a list of all the placeholders,    

| Placeholder                | Description                                                            | Example Value                              |
|----------------------------|------------------------------------------------------------------------|--------------------------------------------|
| `GCP_PROJECT_NUMBER`       | Your GCP Project Number. ([more](#section-2a---gcp-project-details))   | `9876543210`                               |
| `SUB_DOMAIN`               | The desired subdomain for your cluster apps.                           | `dev`                                      |
| `HORIZON_DOMAIN`           | Your desired primary domain name.                                      | `your-domain.com`                          |
| `GCP_PROJECT_ID`           | Your GCP Project ID. ([more](#section-2a---gcp-project-details))       | `my-cloud-project-abc-123`                 |
| `REPOSITORY_URL`           | The URL of your GitHub repository.                                     | `https://github.com/your-gh-org/your-repo` |
| `BRANCH_NAME`              | The branch of your repository to use [more](#branching-strategy)       | `feature-xyz` or `main`                    |
| `GITHUB_ORGANIZATION_NAME` | Your GitHub organization's name. ([more](#section-2c---create-a-github-organization)) | `your-gh-org`               |
| `GITHUB_REPOSITORY_NAME`   | Your GutHub Repository's name. ([more](#section-3c---fork-the-repository)) | `horizon-sdv`                          |
| `GITHUB_ENVIRONMENT_NAME`  | GitHub Environment which holds secrets and variables accessible by GitHub Actions Workflow. ([more](#create-a-github-environment)) | `dev` |


## Section #1 - Prerequisites
### Command-line Tools
> [!NOTE]
> Some of the resources can only be configured via the GUI.

* If you do not prefer using the Cloud Shell on GCP Console, install GCP CLI tools like `gcloud`, `gsutil` and `bq` locally. (Install instructions [here](https://cloud.google.com/sdk/docs/install)).
* If you prefer using the GitHub CLI install ([windows](https://github.com/cli/cli/blob/trunk/README.md#windows) or [Linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md#installing-gh-on-linux-and-bsd)) and [login](https://cli.github.com/manual/gh_auth_login)
* [Git](https://git-scm.com/downloads) is installed and configured.


### GitHub
* Each team-member has GitHub account.
* Team-member with admin privileges able to update configuration in settings such as Secrets and Variables to customize it to use by the team.

### Google Cloud Platform
* Configured GCP account / project.
* Google cloud project with the below APIs enabled:   
   Go to APIs & Services, Enabled APIs & services and click on ENABLE APIS AND SERVCIES and enable the below APIs.
   - IAM Service Account Credentials API
   - Kubernetes Engine API
   - Compute Engine API v1
   - Cloud Filestore API
   - Artifact Registry API
   - Cloud Storage API
   - Service Usage API
   - Secret Manager API
   - Certificate Manager API
* IAM Roles to be granted to the user
   - Compute Admin
   - Kubernetes Engine Admin
   - Artifact Registry Administrator
   - Cloud Filestore Editor
   - Storage Admin

## Section #2 - GCP Foundation Setup
This section covers creation and configuration of required Google Cloud Platform (GCP) services.

### Section #2a - GCP Project details
> [!NOTE]
> The details shown below are only for example and may vary on your environment. 

It is required to perform the checks mentioned in this section as this information will be required later in the setup process.     

1. Default Google Compute Engine (GCE) Service Account:
   * On the console, click on IAM & Admin then, click on Service Accounts and confirm a Service Account for the GCE service is present.  
     <img src="images/gcp_gce_sa.png" width="400" />
2. Project ID and Project Number.
   * Click on the Google Cloud logo on the top left of the page which leads to the welcome page.   
      <img src="images/gcp_welcome_page.png" width="400" />
   * Click on Dashboard where you can find the details mentioned in the Project info Card as below.   
      <img src="images/gcp_dashboard.png" width="400" />

<details>
<summary><code>gcloud</code> CLI</summary>
<ol>
<li>
Default Compute Service Account
<pre>
<code>gcloud iam service-accounts list \
   --filter="email ~ [0-9]+-compute@developer.gserviceaccount.com" \
   --format="value(email)"
</code>
</pre>
</li>
<li>
GCP Project details
<pre>
<code>gcloud projects describe &lt;GCP_PROJECT_ID&gt;</code>
</pre>
</li>
</ol>
</details>

### Section #2b - Create a Bucket in GCP
In the current GCP project, it is required to create a GCP Bucket to store data related to the infrastructure. Follow the below steps to create a Bucket.
1. On the GCP Console, navigate to Cloud Storage and click on Buckets.
2. Click on CREATE/CREATE BUCKET button.
3. Enter a globally unique name for the bucket. (Example: `my-cloud-project-abc-123-bucket`)
4. Click on CONTINUE with default options for other sections.
5. Click on CREATE.
6. If any pop-up window appears, click on CONFIRM.

<details>
<summary><code>gcloud</code> CLI</summary>
<pre>
<code>gcloud storage buckets create gs://&lt;GCP_BACKEND_BUCKET_NAME&gt;</code>
</details>

### Section #2c - Create a GitHub Organization
GitHub organization should be created as a few organization details are required for configuring the Workload Identity Federation on GCP. Before we get started on creating a GitHub organization, it is required to have a GitHub account. If you do not have a GitHub account already, sign up [here](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github).

1. Log in to GitHub, click on your profile (top-right corner of the page) and select "Your organizations".
2. Click on "New Organization" under Organizations.
3. Click on "Create a free organization".
4. Enter Organization name of your choice.
5. Enter your email address as the Contact email.
6. Set organization belonging to "My personal account".
7. Complete the verification challenge under Verify your account.
8. Accept the terms of service and click on Next.
9. In the next step, you can add members to the organization or skip and add members later. Click on "Complete setup".

### Section #2d - Setting up GCP IAM & Admin for Terraform Workflow
The first step for successfully running the GitHub Actions workflow is to set the required Identity and Access Management (IAM) resources on GCP for Terraform to be able to provision the infrastructure.   

Below are the resources which are required to be configured:   
1. Workload Identity Federation Pool and Provider
2. Create Service Account.
3. Binding the Service Account to the Workload Identity Federation.   
    
#### Creating a Workload Identity Federation pool and provider
1. Under IAM & Admin, select Workload Identity Federation and click on GET STARTED.
2. Provide all the necessary details
   - Enter Name as "github" and click on CONTINUE.
   - Select OpenID Connect (OIDC) as the provider within Select a provider.
   - Set Provider name and Provider ID as "github-provider" under Provider details.
   - Set the issuer to URL provided by GitHub (`https://token.actions.githubusercontent.com`) for GitHub Actions. Click [here](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform#adding-a-google-cloud-workload-identity-provider) for more information.
   - Note down the Audience URL (shown just below Default audience) as below:
      * example: `"https://iam.googleapis.com/projects/<GCP_PROJECT_NUMBER>/locations/global/workloadIdentityPools/github/providers/github-provider"`
   - Click on CONTINUE.
   - Configure Provider attributes as below:    
      * "google.subject" = "assertion.sub" and click on ADD MAPPING
      * "attribute.actor" = "assertion.actor" and click on ADD MAPPING
      * "attribute.aud" = "assertion.aud" and click on ADD MAPPING
      * "attribute.repository_owner" = "assertion.repository_owner" and click on ADD MAPPING
      * "attribute.repository" = "assertion.repository"
   - Click on ADD CONDITION under Attribute Conditions.
   - Configure Attribute Conditions as below
      * Condition CEL = "assertion.repository_owner=='GITHUB_ORGANIZATION_NAME'"
   - Click save.
3. Workload Identity Federation Pool and Provider has now been created successfully.   
   <img src="images/gcp_workload_identity_pool_1.png" width="750" />

<details>
<summary><code>gcloud</code> CLI</summary>
<ol>
<li>
Create a Workload Identity Pool
<pre>
<code>gcloud iam workload-identity-pools create github \
   --location=global \
   --display-name="github" \
   --description="Workload Identity Pool for GitHub Actions"
</code>
</pre>
</li>
<li>
Create a Workload Identity Federation Provider
<pre>
<code>gcloud iam workload-identity-pools providers create-oidc github-provider \
   --workload-identity-pool=github \
   --location=global \
   --display-name="github-provider" \
   --description="GitHub OIDC Provider" \
   --issuer-uri="https://token.actions.githubusercontent.com" \
   --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository_owner=assertion.repository_owner,attribute.repository=assertion.repository" \
   --attribute-condition="assertion.repository_owner=='&lt;GITHUB_ORGANIZATION_NAME&gt;'"
</code>
</pre>
</li>
</ol>
</details>

#### Creating a Service Account
1. Under IAM & Admin, navigate to Service Accounts and click on Create service account.
2. Provide `github-sa` as the name for the Service Account.
3. Click on Create and continue.
4. Now, add Owner and Workload Identity User Role to the Service Account.
   - Under Grant this service account access to project click on Select a role.
   - In Filter, search for "Owner", click on Owner and click on Add another role.
   - Click on Select a role, search for "Workload Identity User" and click on Workload Identity User.
   - Click Continue.
5. Click on Done, your Service Account has now been created successfully.

<details>
<summary><code>gcloud</code> CLI</summary>
<ol>
<li>
Create service account
<pre>
<code>gcloud iam service-accounts create github-sa \
   --display-name="Service Account for GitHub Actions"
</code>
</pre>
</li>
<li>
Add <code>Owner</code> role to the service account
<pre>
<code>gcloud projects add-iam-policy-binding &lt;GCP_PROJECT_ID&gt; \
   --member="serviceAccount:github-sa@&lt;GCP_PROJECT_ID&gt;.iam.gserviceaccount.com" \
   --role="roles/owner"
</code>
</pre>
</li>
<li>
Add <code>Workload Identity User</code> role to the service account
<pre>
<code>gcloud projects add-iam-policy-binding &lt;GCP_PROJECT_ID&gt; \
   --member="serviceAccount:github-sa@&lt;GCP_PROJECT_ID&gt;.iam.gserviceaccount.com" \
   --role="roles/iam.workloadIdentityUser"
</code>
</pre>
</li>
</ol>
</details>

#### Binding Service Account to the Workload Identity Provider
1. To bind this Service Account to the Workload Identity Provider, Navigate to the the Workload Identity Pool created earlier.
2. Click on the name of the Workload Identity pool with Display Name as "github" in the list.
2. Click on GRANT ACCESS and select **Grant access using Service Account impersonation**.
3. Select `github-sa` as the Service Account under Select service account.
4. Select Attribute name as `repository_owner` and attribute value as `GITHUB_ORGANIZATION_NAME` under Select principals (identities that can access the service account) and click on SAVE.
5. In the next window, select Provider as `github-provider` from the drop-down menu and set OIDC ID token path as `https://token.actions.githubusercontent.com`.
6. Download the config file and and click on DISMISS.
7. Confirm the Service account has been bound successfully under CONNECTED SERVICE ACCOUNTS tab.   
   <img src="images/gcp_workload_identity_pool_2.png" width="750" />

### Section #2e - Create OAuth2 client and secret
It is required to setup OAuth consent screen before creating the OAuth client and secret. Navigate to APIs & Services and follow the below mentioned steps

#### Setting up OAuth consent screen
Once in APIs & Services, click on OAuth consent screen to start the setup process.

1. Under Overview, click on GET STARTED.
2. Enter "Horizon - SDV" as the App name and select User support email of your choice.
3. Click on NEXT.
4. Under Audience, select External and click on NEXT.
5. Under Contact Information, provide an email address of your choice and click on NEXT.
6. Click on the checkbox under Finish and click on CONTINUE.
7. Click on CREATE.
8. Now, click on Branding. Scroll down and find App domain section.
9. Provide Application home page under App domain, example: `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>`
10. Under Authorized domains, click on ADD DOMAIN and Provide Authorized domain 1 name, example: `<HORIZON_DOMAIN>`
11. Click on SAVE.
12. Click on Audience, under Test users section, click on ADD USERS and add email addresses of users to enable access and click on SAVE.   
   <img src="images/gcp_oauth_consent_screen.png" width="650" />   

#### Create OAuth client ID
1. Go to APIs & Services, click on Credentials.
2. Click on CREATE CREDENTIALS and select "OAuth client ID" from the list.
3. Select Application type as "Web application".
4. Provide Name as "Horizon".
5. Under Authorized redirect URIs enter the URI which points google endpoint of Keycloak.   
   Example: `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>.com/auth/realms/horizon/broker/google/endpoint`.
6. Clicking on CREATE opens a pop-up window containing client ID and secret which can be copied and saved locally to a file or download the credential detail as a JSON file. Click on OK for the pop-up window to close.    
   <img src="images/gcp_oauth_client_details.png" width="325" />
7. The credential will appear Under OAuth 2.0 Client IDs as below and credential details can be viewed and edited by clicking on the Name of the OAuth 2.0 Client ID.   
   <img src="images/gcp_oauth_client_list.png" width="325" />

### Section #2f - Create a DNS Zone (Optional)
Follow the steps mentioned in this section only if you do not have DNS Zone setup already or you wish to bring your desired Domain name.

#### Prerequisites
1. Domain name to be managed.
2. Enable Cloud DNS API.

#### Create a Managed Zone
1. On the Google Cloud console, search for Network Services and click on Cloud DNS.
2. Click on CREATE ZONE.
3. Set the Zone type to be Public.
4. Enter a Zone name of your choice. (example: `your-domain.com`) and click on CREATE.

#### Retrieve the Google Cloud DNS Name Servers
1. In Cloud DNS, click on your Zone name which opens the Zone details.
2. Under RECORD SETS, look for an entry of Type "NS" and click on it to open details.
3. Copy all four entries under Routing data which is required for the next step.

#### Update Name Servers at your Domain Registrar
The steps mentioned in this section may vary based on your Domain name registrar.

1. Log in to your Domain Registrar. (e.g., GoDaddy, Namecheap, Google Domains, etc.)
2. Find DNS Management or Name Server Settings section for your domain.
3. Replace the current name servers with the four Google Cloud DNS name servers you noted down in step previous step.

#### Add DNS Records to your Managed Zone
1. In Cloud DNS, click on your Zone name which opens the Zone details.
2. Under RECORD SETS, click on ADD STANDARD.
   * 'A' record:
      1. Enter DNS name, `<SUB_DOMAIN>`  will be added as a prefix to your domain `<HORIZON_DOMAIN>`.
      2. Set Resource record type to `A`.
      3. Under IPv4 Address, enter the IP Address of the load balancer.
      4. You can find the load balancer IP by navigating to Network Services, Load balancing click on the name of the load balancer with Protocol `HTTPS`.
      5. Copy the IP Address only without the port, under Frontend required by the 'A' record. (point 3)
      6. After pasting the required IP Address, click on CREATE.
   * 'CNAME' record:   
      The details for creating `CNAME` record can be populated after the completion of [Section #5b - Retrieve Certificate's DNS Authz resources](#section-5b---retrieve-certificates-dns-authz-resources).
      1. Enter the value under `DNS Record Name` for DNS Name.
      2. Enter the value under `DNS Record Data` for Canonical name.
      3. Click on CREATE.

DNS changes take anywhere from a few minutes to 24-48 hours to propagate across the internet, depends upon the TTL values and DNS caching.

## Section #3 - GitHub Foundation Setup

### Section #3a - Setup GitHub Organization and Repository
In this section, steps for configuring a GitHub organization and repository are mentioned. For creating a GitHub Organization, refer [Section #2c - Create a GitHub Organization](#section-2c---create-a-github-organization)

#### Create a GitHub Repository
1. Go to the Organization, under Repositories tab click on "New repository".
2. Make sure the Owner field matches the Organization name. If not, select the correct Owner from the drop-down list.
3. Enter the name of the repository of your choice.
4. Select "Public" for the repository visibility.   
   <img src="images/github_create_repository.png" width="750" />
5. Click on Create repository.

<details>
<summary><code>gh</code> CLI</summary>
Create public GitHub repository.
<pre>
<code>gh repo create &lt;GITHUB_ORGANIZATION_NAME&gt;/&lt;GITHUB_REPOSITORY_NAME&gt; --public</code>
</pre>
</details>

### Section #3b - Create GitHub Application
1. Go to the GitHub organization settings tab, scroll down and click on Developer settings and select "GitHub Apps".
2. Click on "New GitHub App".
   * Enter the GitHub App name as "horizon-sa" (If the name has already been taken, provide your desired post-fix for the app name instead of "sa")
   * Enter `https://github.com/` as the Homepage URL.
   * Scroll down and uncheck the "Active" checkbox Under Webhook.
   * Under Permissions, click on Repository permissions and update Access for Contents to "Read-only". (This change will update Metadata permission to Read-only)   
      <img src="images/github_app_contents_permission.png" width="750" />
3. Click on Create GitHub App.
4. To create a Private Key, 
   * Go to Organization, Settings, Developer settings, GitHub Apps and click on the "Edit" Button for "horizon-sa".
   * Scroll down and under Private keys, click on "Generate a private key"   
      <img src="images/github_app_private_key_generation.png" width="425" />
   * Download and Save the `.pem` file to your machine locally.   
5. To note down the GitHub App ID, navigate to Organization, Settings, Developer settings, GitHub Apps and click on "horizon-sa" and note down the info as shown below   
   <img src="images/github_app_id.png" width="450" />
6. Installing the GitHub App
   * Go to Organization, Settings, Developer settings, GitHub Apps and click on "horizon-sa".
   * Click on Install App.
   * Click on Install, select "All repositories" and click on "Install" again.
7. To verify the installation, go to Organization settings and click on GitHub Apps and it should look like below.   
   (GitHub App name may differ in your environment)     
   <img src="images/github_app_confirm_installation.png" width="750" />

### Section #3c - Fork the repository
Below steps are for forking the repository to your GitHub organization.

1. On the repository GitHub page, click on fork drop-down list and select "Create a new fork".   
   <img src="images/github_create_fork_1.png" width="425" />
2. Select your GitHub organization as Owner and click on "Create fork".   
   <img src="images/github_create_fork_2.png" width="750" />
3. The repository should now be available on your GitHub Organization.

<details>
<summary><code>gh</code> CLI</summary>
Fork repository to your GitHub organization.
<pre>
<code>gh repo fork &lt;SOURCE_GITHUB_ORGANIZATION_NAME&gt;/&lt;SOURCE_GITHUB_REPOSITORY_NAME&gt; --org &lt;GITHUB_ORGANIZATION_NAME&gt;</code>
</pre>
</details>

### Section #3d - Set up GitHub Environment
In this section we will be setting up the GitHub repository environment with the required environment secrets and variables.

#### Create a GitHub environment
It is important to name your GitHub environment based on your branching strategy. For each `env/<BRANCH_NAME>`, you must create an environment with name `<BRANCH_NAME>` having its own set of environment secrets and variables.   
Refer [Branching strategy](#branching-strategy) for more information.

1. Navigate to the forked repository on your GitHub organization and switch to the Settings tab.
2. From Settings tab, go to "Environments".   
   <img src="images/github_create_environment.png" width="750" />
3. Click on "New environment" and name it as "<BRANCH_NAME>" (where "<BRANCH_NAME>" is a part of "env/<BRANCH_NAME>") and click on "Configure environment".

<details>
<summary><code>gh api</code> command</summary>
Create Github Environment
<pre>
<code>gh api -X PUT /repos/&lt;GITHUB_ORGANIZATION_NAME&gt;/&lt;GITHUB_REPOSITORY_NAME&gt;/environments/&lt;GITHUB_ENVIRONMENT_NAME&gt;</code>
</pre>
</details>

#### Add Environment secrets
> [!IMPORTANT]
> The credentials below are for demonstration purposes and may be different for your environment.
> Create a strong password with at least 12 characters in length and containing a combination of,
> - uppercase letters [A -Z]
> - lowercase letters [a -z]
> - numbers [0 - 9]
> - Symbols [!@#$%^&* etc.]
>
> Failing do to so might lead to unstable and unsecure cluster.

1. Clicking on "Add environment secrets" under Environment secrets opens a new "Add secret" window where the secret Name and Value can be provided.   
   <img src="images/github_environment_secret_1.png" width="425" />
2. After entering the details of the secret, click on "Add secret".   
   <img src="images/github_environment_secret_2.png" width="750" />
3. Below is the list of all the secrets to be created along with the steps to create them.
   * GH_APP_ID
      - Navigate to Organization Settings, Developer settings, GitHub Apps and click on "horizon-sa" and note down the info as shown below   
      <img src="images/github_app_id.png" width="450" />
   * GH_APP_KEY
      - Enter the details of the downloaded `.pem` key file 
        created in [Section #3b - Create GitHub Application](#section-3b---create-github-application), point number 4.
   * GH_INSTALLATION_ID
      - Navigate to Organization Settings, GitHub Apps and click on "Configure".
      - Once in the GitHub App configuration page, the `GH_INSTALLATION_ID` is present in the URL of the page as below,
         - `https://github.com/organizations/<GH-ORG-NAME>/settings/installations/<INSTALLATION_ID>`
      - Enter the value of `<INSTALLATION_ID>`
   * GCP_SA
      - On the GCP Console, go to IAM & Admin, Service Accounts, copy the email name `github-sa@<GCP_PROJECT_ID>.iam.gserviceaccount.com`
        from the table.
   * WIF_PROVIDER
      - On the GCP Console, go to IAM & Admin, Workload Identity Federation, click on github provider pool.
      - Once the pool details open, from the providers tab on the right of the page, click on edit icon.
      - Scroll up and copy the URL mentioned under "Audiences" and paste only the part starting from `projects/.../github-provider`
         - example: `projects/<GCP_PROJECT_NUMBER>/locations/global/workloadIdentityPools/github/providers/github-provider`
   * ARGOCD_INITIAL_PASSWORD
      - You can create your desired strong password.
   * CUTTLEFISH_VM_SSH_PRIVATE_KEY
      - If you are using a Windows machine, you can generate the key using below commands using [WSL](https://learn.microsoft.com/en-us/windows/wsl/about).
      - Or you can use the [google cloud shell](https://cloud.google.com/shell/docs/launching-cloud-shell#launch_from_the), here it is important to save the keys to your machine locally as the data on the cloud shell machine may not persist.
      - Run the below command to generate the SSH keys. 
        ```
        mkdir -p cuttlefish_vm_keys && ssh-keygen -t rsa -b 4096 -f ./cuttlefish_vm_keys/my_cuttlefish_vm_ssh_key && cat ./cuttlefish_vm_keys/my_cuttlefish_vm_ssh_key
        ```
      - example:
      > When copying the private key, ensure there is a newline character at the very end. 
      > Missing this newline can sometimes lead to instability or issues with SSH authentication.
        ```
        -----BEGIN OPENSSH PRIVATE KEY-----
         b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
         ...
         AIFvukjAZRbHAAAAB2plbmtpbnMBAgM=
         -----END OPENSSH PRIVATE KEY-----

        ```
   * GERRIT_ADMIN_INITIAL_PASSWORD
      - You can create your desired strong password.
   * GERRIT_ADMIN_PRIVATE_KEY
      - If you are using a Windows machine, you can generate the key using below commands using [WSL](https://learn.microsoft.com/en-us/windows/wsl/about).
      - Or you can use the [google cloud shell](https://cloud.google.com/shell/docs/launching-cloud-shell#launch_from_the), here it is important to save the keys to your machine locally as the data on the cloud shell machine may not persist.
      - Run the below command to generate the SSH keys
        ```
        mkdir -p gerrit_admin_keys && ssh-keygen -t ecdsa -b 521 -f ./gerrit_admin_keys/my_gerrit_admin_ssh_key && cat ./gerrit_admin_keys/my_gerrit_admin_ssh_key
        ```
      - example:
      > When copying the private key, ensure there is a newline character at the very end. 
      > Missing this newline can sometimes lead to instability or issues with SSH authentication.

         ```
         -----BEGIN OPENSSH PRIVATE KEY-----
         b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAaAAAABNlY2RzYS
         ...
         bgECAw==
         -----END OPENSSH PRIVATE KEY-----

         ```
   * JENKINS_INITIAL_PASSWORD
      - You can create your desired strong password.
   * KEYCLOAK_HORIZON_ADMIN_PASSWORD
      - You can create your desired strong password.
   * KEYCLOAK_INITIAL_PASSWORD   
      - You can create your desired strong password.
4. Once the Environment secrets have been created, it will be visible as shown below   
   <img src="images/github_environment_secrets_list.png" width="750" />

<details>
<summary><code>gh</code> CLI</summary>
For each environment secret, run the below commands once the repository has been <a href="#clone-the-repository">cloned</a> locally.
<li>
Interactive creation <br>
   Follow this method for typical `secret_name` = `secret_value` items.
<pre>
<code>gh secret set &lt;YOUR_SECRET_NAME&gt; -e &lt;GITHUB_ENVIRONMENT_NAME&gt;</code>
</pre>
</li>
<li>
Providing File path <br>
Use this method for creating secrets which hold private keys.<br>
<code>PRIVATE_SSH_KEY_FILE</code>: Retrieve path and filename while creating private keys in <a href="#add-environment-secrets">Add Environment Secret</a> section.
<pre>
<code>cat /path/to/&lt;PRIVATE_SSH_KEY_FILE&gt; | gh secret set &lt;YOUR_SECRET_NAME&gt; -e &lt;GITHUB_ENVIRONMENT_NAME&gt;</code>
</pre>
</li>
</ol>
</details>

#### Add Environment variables
1. Open repository settings and click on Environments, scroll down and click on "Add environment variable".   
   <img src="images/github_environment_variable_1.png" width="425" />
2. Add environment variables to be created are listed below,
   * GCP_BACKEND_BUCKET_NAME
      - Enter the name of the GCS Bucket created in [Create a Bucket in GCP](#section-2b---create-a-bucket-in-gcp)
   * GCP_CLOUD_REGION
      - Enter the Cloud region of your choice. (example: `europe-west1`)
   * GCP_CLOUD_ZONE
      - Enter the Cloud region of your choice. (example: `europe-west1-d`)
   * GCP_COMPUTER_SA
      - Enter the default compute service account details retrieved from the [Section #2a - GCP Project details](#section-2a---gcp-project-details) point number 1.
      - example: <GCP_PROJECT_NUMBER>-compute@developer.gserviceaccount.com
   * GCP_PROJECT_ID
      - Enter the GCP project ID details retrieved from the [Section #2a - GCP Project details](#section-2a---gcp-project-details) point number 2.
   * HORIZON_DOMAIN
      - Enter the domain name of your choice. (example: `your-domain.com`)
3. Once the Environment variable have been created, it will be visible as shown below   
   <img src="images/github_environment_variable_list.png" width="400" />

<details>
<summary><code>gh</code> CLI</summary>
For each environment variable, run the below commands once the repository has been <a href="#clone-the-repository">cloned</a> locally.
<pre>
<code>gh variable set &lt;YOUR_VARIABLE_NAME&gt; -e &lt;GITHUB_ENVIRONMENT_NAME&gt;</code>
</pre>
</details>

### Section #3e - Setup GitHub repository
This section covers the steps to be followed for cloning the repository to the local machine and creating required branches.

#### Create GitHub Personal Access Token
Creating a GitHub Personal Access Token is required for securely accessing the repository.

1. In your profile settings (top-right corner), open Developer Settings.
2. Clicking on Personal access tokens opens a drop-down, select "Tokens (classic)".
3. Click on "Generate new token and select Generate new token (classic)".   
   <img src="images/github_create_personal_access_token.png" width="750" />
4. Enter a suitable name for the token in the "Note" field and select Expiration of the token based on your requirement. (default set to 30 days)
5. Under "Select scopes", check all the checkboxes to enable all privileges and click on "Generate token".
6. Make sure to copy and save the token as it is displayed only once after token is created.

#### GitHub Personal Access Token Single sign-on
> [!NOTE]
> This section should should only be followed if your GitHub organization offers SSO (Single sign-on). If not, skip this section.

1. In your profile settings (top-right corner), open Developer Settings.
2. Clicking on Personal access tokens opens a drop-down, select "Tokens (classic)".
3. If available, click on configure SSO, which opens a drop-down window and find an organization name between organizations that are "Available to authorize".   
   <img src="images/github_personal_access_token_sso.png" width="425" />
4. Click "Authorize" that corresponds to the GitHub organization name you are working in as shown in the above example.

#### Clone the repository
Before running the below commands, make sure [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) is installed and configured on your local machine.

1. On the repository homepage, click on <img src="images/github_clone_1.png" width="60" /> button and copy the HTTPS URL.   
   <img src="images/github_https_clone.png" width="425" />
2. On your machine, navigate to your desired path and open the terminal and run the below command   
   ```
   git clone <REPOSITORY_URL>
   ```

#### Branching strategy
Once you clone the repository to your machine, it may contain a single `main` branch from which you can create new `feature/` and `env/` branches for development purposes.   

* `main`
* `env/<BRANCH_NAME>`
* `feature/<BRANCH_NAME>`

From the above list of branches, the `env/<BRANCH_NAME>` can be associated to a project on GCP and have its own environment secrets and variables configured in the GitHub repository.   

For development, you may create new `feature/<BRANCH_NAME>` which can be merged into `env/<BRANCH_NAME>` after code review and passing all tests. 
You can create multiple `env/<BRANCH_NAME>` branch according your needs. For example, `env/sbx` branch focusing only on IaC or GitOps, 
`env/dev` branch focusing only on workloads and so on.   

Each `env/<BRANCH_NAME>` branch can perform dedicated platform or workload related tasks. Details on applying changes are as below,

* Platform (`env/sbx`)
   * Applying changes to the GitHub Actions Workflow
      - Create a `feature/<BRANCH_NAME>` branch, edit the files under `.github/workflows/` directory.
      - Once the changes have been made, merge the `feature/<BRANCH_NAME>` branch to `env/<BRANCH_NAME>` branch.
      - If adding new workflows or renaming existing ones, `main` branch must be updated.
      - If only changing existing workflows, updating `main` branch immediately is not required.
      - Run the GitHub workflow manually.

   * Applying changes to the infrastructure using Terraform (IaC)
      - Create a `feature/<BRANCH_NAME>` branch, edit the files under `terraform/` directory.
      - You can run `terraform plan` locally if you have terraform installed.
      - Navigate to the `terraform/` directory, and run `cd env && source local-env.sh` which sets up the environment variables.
      - Now, run `terraform plan`.
      - If the plan is successful and the outcome aligns with your objective, merge the branch to `env/<BRANCH_NAME>`.
      - Run the GitHub Actions workflow manually by selecting the desired `env/<BRANCH_NAME>`.
      - The above manual workflow trigger step runs `terraform apply` which will cause changes to the infrastructure, 
      it is advised to take caution.

   * If you want to make changes to the Kubernetes Applications (GitOps)
      - Create a `feature/<BRANCH_NAME>` branch, edit the files under `gitops/` directory.
      - [Log in](#section-6a---argo-cd) to Argo CD and switch the "horizon-sdv" application branch to a feature branch in ArgoCD.
      - Modify files under `gitops/` directory with your desired changes, refresh and sync changes in ArgoCD.
      - Test the changes. If successful, merge the branch to `env/<BRANCH_NAME>`.
      - Switch the "horizon-sdv" application branch to the default `env/<BRANCH_NAME>` branch.

* Workloads (`env/dev`)
   * Making changes to the Workloads
      - Create a `feature/<BRANCH_NAME>` branch, edit the files under `workloads/` directory.
      - You can update the workload behavior accordingly.
      - If the change impacts any of the GitOps applications (example: Jenkins), make sure that this application is ready for 
      testing and it meets required preconditions.
      - Merge the branch to `env/<BRANCH_NAME>` and restart the application if required.

#### Create a new branch
Create a new branch with `main` branch as the base.

1. Run the below command to make sure you are on the `main` branch.   
   ```
   git branch
   ```
2. If you are not on the main branch, run one of the below command to switch to the `main` branch.
   ```
   git checkout main
   ```   
   or   
   ```
   git switch main
   ```
3. Once you are on the `main` branch, run one of the below command to create a new branch and switch to it. 
Name it as `env/<BRANCH_NAME>`   
   ```
   git checkout -b env/<BRANCH_NAME>
   ```
   or
   ```
   git switch -c env/<BRANCH_NAME>
   ```
You can use the above steps to create `feature/<BRANCH_NAME>` branches as well.

### Pushing changes to remote GitHub repository
Once you have made your edits and saved the configuration files, follow the below steps to push the changes to the 
remote repository on GitHub.

1. Make sure you have checked-out to the branch of your choice using,
   ```
   git checkout -b env/<BRANCH_NAME>
   ```
   or
   ```
   git switch -c env/<BRANCH_NAME>
   ```
2. Run the below command to push the changes,
   ```
   git push origin env/<BRANCH_NAME>
   ```
You can use the above steps to push changes in `feature/<BRANCH_NAME>` branches to remote repository as well.


## Section #4 - Trigger GitHub Actions Terraform Workflow
Follow the below steps to trigger a terraform workflow run.

1. Go to the GitHub repository.
2. Click on the "Actions" tab.
3. Select the "Terraform" workflow from the list.
4. Click on "Run workflow", select the branch required and click on "Run workflow"   
   <img src="images/github_actions_terraform_workflow_trigger.png" width="725" />

## Section #5 - Post Terraform Workflow Setup

### Section #5a - Retrieve Load balancer details
The steps mentioned in this section is to be performed after the Terraform workflow is completed and the resources on GCP have been provisioned successfully.

1. On the GCP Console, search for "Network Services".
2. Click on Load balancing and under the LOAD BALANCER TAB, click on the Name of the Load balancer with Protocols set to "HTTPS" as shown in below example   
   <img src="images/gcp_load_balancer_1.png" width="750" />
3. Under "Frontend", copy the IP Address details in the table as shown below example    
   <img src="images/gcp_load_balancer_2.png" width="750" />

### Section #5b - Retrieve Certificate's DNS Authz resources
> [!IMPORTANT]
> This step must be completed within 30 minutes of certificate creation. Failure will complicate recovery.

In this section, we will be retrieving DNS details required for the DNS setup.   

1. On the Cloud console, navigate to Security, scroll down and click on "Certificate Manager".
2. Under the CERTIFICATES tab, click on the Certificate's name which in this case is "horizon-sdv".
3. Now, scroll down to the bottom of the certificate details page which contains the required details under "Certificate's DNS Authz resources".
4. From the Certificate's DNS Authz resources details table, copy the values of `DNS Record Name` and `DNS Record Data` as shown in below example.   
   <img src="images/gcp_certificate_dns_authz.png" width="750" />
5. Share the above Certificate's DNS Authz resources details are required for populating the CNAME record in the DNS Zone.

### Section #5c - Setup Keycloak
Follow the steps mentioned in this section once the cluster is provisioned and is running successfully to configure Keycloak.

#### Login as Horizon admin
1. Keycloak UI can be accessed here: `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>/auth/admin/horizon/console`.
2. Login to Keycloak as admin with below credentials,
   - username: `horizon-admin`
   - password:  Use value of `KEYCLOAK_HORIZON_ADMIN_PASSWORD` as configured in [Add Environment secrets](#add-environment-secrets) section.
3. On your first login, you may be prompted to update your password. Create a new, strong password, confirm it, and click Submit.
4. On the next screen, enter your email address, first name, and last name as below.
   - Email Adress: `horizon.admin@keycloak.com`
   - First name: `horizon`
   - Last name: `admin`
5. Click Submit.

#### Configure Google Identity Provider
1. Login to Keycloak and click on "Identity providers".
2. Click "Add provider" and select "Google" provider.
3. Ensure that the Redirect URI matches the one set in the [Create OAuth client ID](#create-oauth-client-id) section.
4. Enter the values for `Client ID` and `Client Secret` as mentioned in the step 7 of the section [Create OAuth client ID](#create-oauth-client-id).   
   <img src="images/keycloak_google_identity_provider.png" width="750" />
5. Click on Add.

#### Configure a new Authentication flow
1. Login to Keycloak, navigate to Authentication and click "Create flow". Name it as "broker link existing user" and click on Create.
2. Click "Add execution".
3. In the pop-up search box, search for "Detect existing broker user" and click on "Add".   
   <img src="images/keycloak_create_authentication_flow_1.png" width="750" />
4. Switch the value of "Requirement" field for the step "Detect existing broker user" to "Required" from the drop-down list as below   
   <img src="images/keycloak_create_authentication_flow_2.png" width="750" />
5. Click on "Add step".
6. In the pop-up search box, search for "Automatically set existing user" and click on "Add".   
   <img src="images/keycloak_create_authentication_flow_3.png" width="750" />
7. Switch the value of "Requirement" field for the step "Automatically set existing user" to "Required" from the drop-down list as below   
   <img src="images/keycloak_create_authentication_flow_4.png" width="750" />
8. Next, go to "Identity providers" and select "google".
9. Click on "Advanced settings" look for "First login flow override". Switch the value of "First login flow override" to "broker link existing user" as shown below   
   <img src="images/keycloak_create_authentication_flow_5.png" width="750" />
10. Finally, click on "Save".

#### Create first human admin user
After logging in as the Horizon admin, follow these steps to create a human user account with administrative privileges:

1. Click on Users, then click on Add user.
2. Toggle Email Verified to On.
3. Enter the required details for username, email, first name, and last name. (Note: Use the full email address for both the username and email fields.)
4. Click on Create.
5. On the next page, switch to Role mapping tab and click on Assign role.   
   <img src="images/keycloak_assign_role_1.png" width="750" />
6. Make sure the value of Filter by is set to "Filter by clients".
7. Search for "realm_admin" and click on the checkbox to select the role.
8. Click on Assign.   
   <img src="images/keycloak_assign_role_2.png" width="750" />
9. Switch to the Details tab, click on Save.
10. Click on username on top right corner of the page and click on Sign out.
11. Log in using the newly created human admin account to perform subsequent configurations. (Sign in with Google)

Repeat the above steps to add additional users with the required access privilege level.

## Section #6 - Run Cluster Apps
This section details how to sign in to and use cluster applications, including their functionalities within the cluster environment.

### Section #6a - Argo CD
Argo CD is the GitOps tool being used with GitHub as the "source of truth" where the desired state of Kubernetes applications have been configured. 
It ensures the Kubernetes Cluster (GKE) always matches that desired state. Here, Argo CD is configured to automatically sync so, no user intervention is usually required.  

To Access Argo CD UI, go to `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>/argocd` and log-in using the credentials configured in section [Add Environment secrets](#add-environment-secrets).   

<details>
  <summary>Click for more details on Argo CD</summary>

   #### View Application Status
   Check the health and sync status (synced or out-of-sync) and overall status of the deployed applications as below from the home page.   
   <img src="images/argo_cd_1.png" width="750" />

   #### Monitor Application Health
   Check the health status of individual resources within an application (deployments, services, etc.).
   You can click on any application to further investigate the status and health of individual apps.   
   <img src="images/argo_cd_2.png" width="750" />

   #### Inspect Application Resources
   > :warning: WARNING   
   > It is not recommended to edit files using Argo CD GUI as it may lead to conflict in desired
   > state of the cluster

   View the Kubernetes resources `.yaml` manifests that defines an application. You can do this by clicking on any application of your choice from the home page and then click on any resource you would like to inspect, change to "manifest" tab.   
   <img src="images/argo_cd_3.png" width="750" />

   #### View Application Events
   View events related to application deployment, sync, and health changes. You can do this by clicking on any application of your choice from the home page and then click on any resource you would like to inspect, change to "events" tab.   
   <img src="images/argo_cd_4.png" width="750" />

   #### Trigger Manual Sync
   Force an application to synchronize with the Git repository to apply latest changes. To force an application to sync, you can click the sync button as below,   
   <img src="images/argo_cd_5.png" width="325" />   
   This will open another window where you can further apply more sync options based on your needs and click on "synchronize".

   #### Additional operations that you can perform using Argo CD
   1. View Application History/Rollback: See the deployment history and rollback to a previous application version.
   2. Compare Application Versions (Diff): See the differences between the currently deployed application and the desired state in Git.
   3. Delete Applications: Remove applications deployed by Argo CD.
   4. View Application Logs (Potentially): Access logs of application components (depending on setup and integrations).
</details>   

### Section #6b - Keycloak
Keycloak is the Identity and Access Management (IAM) application provides features like authentication and authorization. It centralizes user management for all applications on the cluster.   

You can access Keycloak for your cluster by going to `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>/auth/admin/horizon/console` and login using the credentials configured in section [Add Environment secrets](#add-environment-secrets).   

Refer section [Section #5c - Setup Keycloak](#section-5c---setup-keycloak) for steps to create and manage users.   
   
<img src="images/keycloak_homepage.png" width="750" />

### Section #6c - Gerrit
Gerrit is a web-based code review tool built on top of the git version control system.

Gerrit can be accessed by going to `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>/gerrit` and login using google sign-in.   

<img src="images/horizon_login_with_google.png" width="300" />   

Below is a view of Gerrit homepage,   
<img src="images/gerrit_homepage.png" width="750" />

### Section #6d - Jenkins
Jenkins is an open-source automation server. It's primary use-case is to automate tasks related to running Android workloads on the cluster. It is a core tool for Continuous Integration and Continuous Delivery pipelines.

Jenkins can be accessed by going to `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>/jenkins` and login using google sign-in.

<img src="images/horizon_login_with_google.png" width="300" />   

Below is a view of the Jenkins dashboard,   
<img src="images/jenkins_dashboard.png" width="750" />

### Section #6e - MTK connect
MTK Connect provides connectivity to remote devices for automated and manual testing.   

MTK connect can be accessed by going to `https://<SUB_DOMAIN>.<HORIZON_DOMAIN>/mtk-conect` and login using google sign-in.   

<img src="images/horizon_login_with_google.png" width="300" />    

Below is a view of the MTK connect homepage,   
<img src="images/mtk-connect_homepage.png" width="750" />

## Section #7 - Deprovisioning Infrastructure
This section contains the steps to destroy the environment provisioned by Terraform workflow. 
Follow the below steps to successfully destroy the infrastructure.

>[!NOTE]
> Only the resources provisioned by Terraform will be removed. Resources created or configured manually will not be affected.

### Section #7a - Install Terraform
Run the below command in [Cloud Shell](https://cloud.google.com/shell/docs/launching-cloud-shell#launch_from_the) to install the latest version of Terraform.
```
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Section #7b - Terraform Destroy
In this section, we will be setting up Terraform on Google [Cloud Shell](https://cloud.google.com/shell/docs/launching-cloud-shell#launch_from_the) 

1. Check if terraform is installed.
   ```
   terraform version
   ```
2. Clone the GitHub repository.
   ```
   git clone <REPOSITORY_URL>
   ```
3. Switch to the branch you selected for the Terraform workflow.
   ```
   cd <REPOSITORY_NAME> && git switch <BRANCH_NAME>
   ```
4. Edit the required environment variables under `GCP configuration variables` with the project details using the below command.
   ```
   cd terraform/env && nano local-env.sh
   ```
   Press `ctrl+s` and `ctrl+x` to save and exit.
5. Initialize the environment variables.
   ```
   source local-env.sh
   ```
6. Run the below command to initialize terraform.
   ```
   terraform init -input=false -backend-config bucket="<GCP_BACKEND_BUCKET_NAME>"
   ```
   The output should contain `Successfully configured the backend "gcs"! Terraform will automatically`   
   The name of bucket will be the same as mention in [Section #2b - Create a Bucket in GCP](#section-2b---create-a-bucket-in-gcp).
7. Run the below command to list the contents of the state data.
   ```
   terraform state list
   ```
8. To destroy the infrastructure provisioned by Terraform, run the below command and type "yes" when prompted to confirm.
   ```
   terraform destroy
   ```

## Section #8 - Troubleshooting

### Section #8a - Keycloak sign-in failure
Check the below sections for issues related to sign-in after the cluster has been provisioned and Keycloak is setup with google identity provider.

#### Redirect URI mismatch
- Log-in to Keycloak and select "Horizon" realm.
- Go to Identity providers and click on "google" provider.
- Copy the redirect URI available in the google identity provider.
- Now, go to "APIs & Services" click and open "Credentials".
- Click on "Horizon" under OAuth 2.0 Client IDs.
- Make sure the URI mentioned under "Authorized redirect URIs" is the same as the one in Keycloak google provider.
- If the URIs do not match, replace the URI mentioned under "Authorized redirect URIs".

#### User does not exist with google identity provider
If you are getting the error "User <USER_NAME> authenticated with Identity provider google does not exist. Please contact your administrator".   
- Log-in to Keycloak and select "Horizon" realm.
- Go to Users, click on your user.
- make sure both Username and Email fields have the complete Email address.

## LICENSE
Refer to the [LICENSE](../LICENSE) file for license rights and limitations (Apache 2.0).

