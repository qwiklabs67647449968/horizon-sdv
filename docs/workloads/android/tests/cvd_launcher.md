# CVD Launcher Pipeline

## Table of contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Environment Variables/Parameters](#environment-variables)
- [Example Usage](#examples)
- [System Variables](#system-variables)

## Introduction <a name="introduction"></a>

This pipeline is run on GCE Cuttlefish VM instances from the instance templates that were previously created by the environment pipeline. It allows users to test their Cuttlefish virtual device (CVD) image builds.

The pipeline first runs CVD on the Cuttlefish VM Instance to instantiate the specified number of virtual devices and then connects to MTK Connect so that users can test their builds (UI and adb). Devices are kept alive for the user-specified amount of time.

### References <a name="references"></a>

- [Cuttlefish Virtual Devices](https://source.android.com/docs/devices/cuttlefish)
- [Android Cuttlefish](https://github.com/google/android-cuttlefish)

## Prerequisites<a name="prerequisites"></a>

One-time setup requirements.

- Before running this pipeline job, ensure that the following templates have been created by running the corresponding jobs:
  - Docker image template: `Android Workflows/Environment/Docker Image Template`
  - Cuttlefish instance template: `Android Workflows/Environment/CF Instance Template`

## Environment Variables/Parameters <a name="environment-variables"></a>

### `JENKINS_GCE_CLOUD_LABEL`

This is the label that identifies the GCE Cloud label which will be used to identify the Cuttlefish VM instance, e.g.

- `cuttlefish-vm-main`
- `cuttlefish-vm-v110`

Note: The value provided must correspond to a cloud instance or the job will hang.

### `CUTTLEFISH_DOWNLOAD_URL`

This is the Cuttlefish Virtual Device image that is to be tested. It is built from `AAOS Builder` for the `aosp_cf` build targets.

The URL must point to the bucket where the host packages and virtual devices images archives are stored:

- `cvd-host_package.tar.gz`
- `osp_cf_x86_64_auto-img-builder.zip`

URL is of the form `gs://<ANDROID_BUILD_BUCKET_ROOT_NAME>/Android/Builds/AAOS_Builder/<BUILD_NUMBER>` where `ANDROID_BUILD_BUCKET_ROOT_NAME` is a system environment variable defined in Jenkins CasC `jenkins.yaml` and `BUILD_NUMBER` is the Jenkins build number.

### `CUTTLEFISH_MAX_BOOT_TIME`

Cuttlefish virtual devices need time to boot up. This defines the maximum time to wait for the virtual device(s) to boot up. Cuttlefish virtual devices can take a serious amount of time before booting, hence this is quite large.

Time is in seconds.

### `CUTTLEFISH_KEEP_ALIVE_TIME`

If wishing to test using MTK Connect, Cuttlefish VM instance must be allowed to continue to run. This timeout, in
minutes, gives the tester time to keep the instance alive so they may work with the devices via MTK Connect.

### `NUM_INSTANCES`

Defines the number of Cuttlefish virtual devices to launch.

This applies to CVD `num-instances` parameters.

### `VM_CPUS`

Defines the number of CPU cores to allocate to the Cuttlefish virtual device.

This applies to CVD `cpus` parameter.

### `VM_MEMORY_MB`

Defines total memory available to guest.

This applies to CVD `memory_mb` parameter.

## Example Usage <a name="examples"></a>

The following examples show how the scripts may be used standalone on a test instance.

From `Workloads/Android/Environment/CF Instance Template` create a Cuttlefish test instance:

- `ANDROID_CUTTLEFISH_REVISION`: choose the version you wish to build the template from
- `CUTTLEFISH_INSTANCE_UNIQUE_NAME` : provide a unique name, starting with cuttlefish-vm, e.g. `cuttlefish-vm-test-instance-v110.`
- `MAX_RUN_DURATION` : set to 0 to avoid instance being deleted after this time.
- `VM_INSTANCE_CREATE` : Enable this option so that the instance template will create a VM instance for user to start, connect to and work with.

Connect to the instance, e.g.

```
# SSH to bastion host
gcloud compute ssh --zone "europe-west1-d" "sdv-bastion-host" --tunnel-through-iap --project "sdva-2108202401"
# Set up credentials to connect to the VM instance
gcloud container clusters get-credentials sdv-cluster --region europe-west1 --internal-ip

# If user wishes to use MTK Connect then retrieve the MTK Connect API key via bastion:
# Retrieve the MTK_CONNECT_USERNAME:
kubectl get secrets -n mtk-connect mtk-connect-apikey -o json | jq -r '.data.username' | base64 -d
# Retrieve the MTK_CONNECT_PASSWORD:
kubectl get secrets -n mtk-connect mtk-connect-apikey -o json | jq -r '.data.password' | base64 -d

# Start the instance
gcloud compute instances start cuttlefish-vm-test-instance-v110 --zone=europe-west1-d
# Connect to the instance
gcloud compute ssh --zone "europe-west1-d" "cuttlefish-vm-test-instance-v110" --tunnel-through-iap --project "sdva-2108202401"
```
**Authentication Required:** You may be prompted to authenticate during this process. To complete the authentication, follow the on-screen instructions or run `gcloud auth login`.

Once you have access to the instance, follow these steps:

- Clone the Horizon SDV repository on the instance.
- Run the CVD Launcher scripts as per the following examples.

```
CUTTLEFISH_DOWNLOAD_URL="gs://sdva-2108202401-aaos/Android/Builds/AAOS_Builder/10/" \
CUTTLEFISH_MAX_BOOT_TIME=300 \
NUM_INSTANCES=1 \
VM_CPUS=16 \
VM_MEMORY_MB="16384" \
./workloads/android/pipelines/tests/cvd_launcher/cvd_start_stop.sh --start
```

Users should stop CVD and devices with the following command when complete:
```
./workloads/android/pipelines/tests/cvd_launcher/cvd_start_stop.sh --stop
```

**MTK Connect:**

Users may optionally connect devices to MTK Connect in order to utilise the UI. Ensure the devices are running before
following the instructions below.

```
# Start MTK Connect (use the credentials from earlier)
sudo \
MTK_CONNECT_DOMAIN="dev.horizon-sdv.com" \
MTK_CONNECT_USERNAME=${MTK_CONNECT_USERNAME} \
MTK_CONNECT_PASSWORD=${MTK_CONNECT_PASSWORD} \
MTK_CONNECTED_DEVICES=1 \
MTK_CONNECT_TESTBENCH="Example-Testbench" \
./workloads/android/pipelines/tests/cvd_launcher/cvd_mtk_connect.sh --start

# When complete, stop MTK Connect and delete the testbench.
sudo \
MTK_CONNECT_DOMAIN="dev.horizon-sdv.com" \
MTK_CONNECT_USERNAME=${MTK_CONNECT_USERNAME} \
MTK_CONNECT_PASSWORD=${MTK_CONNECT_PASSWORD} \
MTK_CONNECTED_DEVICES=1 \
MTK_CONNECT_TESTBENCH="Example-Testbench" \
./workloads/android/pipelines/tests/cvd_launcher/cvd_mtk_connect.sh --stop || true
```

When testing is complete, it is advisable to stop the instance, e.g.
`gcloud compute instances stop cuttlefish-vm-test-instance-v110 --zone=europe-west1-d`

When entirely finished with the instance, delete it. e.g.

From `Workloads/Android/Environment/CF Instance Template` delete the Cuttlefish test instance:

- `CUTTLEFISH_INSTANCE_UNIQUE_NAME` : provide a unique name, starting with cuttlefish-vm, e.g. `cuttlefish-vm-test-instance-v110.`
- `DELETE` : This ensures the instance template, disk image and VM instance are deleted.

## SYSTEM VARIABLES <a name="system-variables"></a>

There are a number of system environment variables that are unique to each platform but required by Jenkins build, test and environment pipelines.

These are defined in Jenkins CasC `jenkins.yaml` and can be viewed in Jenkins UI under `Manage Jenkins` -> `System` -> `Global Properties` -> `Environment variables`.

These are as follows:

-   `ANDROID_BUILD_BUCKET_ROOT_NAME`
     - Defines the name of the Google Storage bucket that will be used to store build and test artifacts

-   `ANDROID_BUILD_DOCKER_ARTIFACT_PATH_NAME`
    - Defines the registry path where the Docker image used by builds, tests and environments is stored.

-   `CLOUD_PROJECT`
    - The GCP project, unique to each project. Important for bucket, registry paths used in pipelines.

-   `CLOUD_REGION`
    - The GCP project region. Important for bucket, registry paths used in pipelines.

-   `CLOUD_ZONE`
    - The GCP project zone. Important for bucket, registry paths used in pipelines.

-   `HORIZON_DOMAIN`
    - The URL domain which is required by pipeline jobs to derive URL for tools and GCP.

-   `JENKINS_SERVICE_ACCOUNT`
    - Service account to use for pipelines. Required to ensure correct roles and permissions for GCP resources.
