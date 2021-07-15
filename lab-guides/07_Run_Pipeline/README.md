## Run the pipeline for the Carts Service

In this exercise you'll measure the performance for the carts service 3 times. The first time you'll run the test and create a baseline for future runs. The second time you will introduce a small slowdown that will be evaluated as a warning SLO result. The third time you will increase the slowdown to see how the pipelines fails when it goes beyond the SLI objetive for the response time.

### Step 1: Run a first build to set the baseline

1. Go into `Jenkins > sockshop > create-release-branch`, click on `Build with Parameters` and use `carts` as the parameter value to create a new branch for our release to staging. Then go into `Jenkins > sockshop > carts` and click on `Scan Multibranch Pipeline Now` to trigger automatically a new build.
1. Wait until the pipeline build exists with a *Success* status.

### Step 2: Introduce a small slowdown in the Carts Service

1. Navigate to your Gitea repository `carts` `http://gitea.xx.xx.xx.xx.nip.io/perform/carts`, and get to the file: `carts\src\main\resources\application.properties`.
1. Change the value of `delayInMillis` from `0` to `500`.
1. Save and commit your changes.

### Step 3: Build this new Version

1. Go into `Jenkins > sockshop > create-release-branch`, click on `Build with Parameters` and use `carts` as the parameter value to create a new branch for our release to staging. Then go into `Jenkins > sockshop > carts` and click on `Scan Multibranch Pipeline Now` to trigger automatically a new build.
1. Wait until the Jenkins build exists with a *Warning* (yellow) status.

### Step 5: Introduce a larger slowdown in the Carts Service

1. Navigate to your Gitea repository `carts` `http://gitea.xx.xx.xx.xx.nip.io/perform/carts`, and get to the file: `carts\src\main\resources\application.properties`.
1. Change the value of `delayInMillis` from `500` to `800`.
1. Save and commit your changes.

### Step 6: Build this new Version

1. Go into `Jenkins > sockshop > create-release-branch`, click on `Build with Parameters` and use `carts` as parameter to create a new branch for our release to staging. Then go into `Jenkins > sockshop > carts` and click on `Scan Multibranch Pipeline Now` to trigger automatically a new build.
1. Wait until the Jenkins build exists with a *Failure* (red) status.

[Previous Step: Define Pipeline](../06_Define_Pipeline) :arrow_backward: :arrow_forward: [Next Step: Analize Results in Keptn Bridge](../08_Analyze_Results_in_Keptn_Bridge)

:arrow_up_small: [Back to overview](../)
