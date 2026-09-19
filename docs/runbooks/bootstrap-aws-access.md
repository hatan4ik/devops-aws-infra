# Bootstrap AWS Access

To adhere to our **ADR 0001 (Account Structure)** and **Security Baseline**, we avoid long-lived static IAM keys wherever possible. However, for the very first deployment, you must bootstrap access.

## Option A: Bootstrapping via AWS IAM Identity Center (Recommended)
If you have already enabled AWS IAM Identity Center (formerly AWS SSO) in your management account:

1. Open your terminal and run:
   ```bash
   aws configure sso
   ```
2. **SSO start URL**: Enter your AWS SSO portal URL (e.g., `https://my-sso-portal.awsapps.com/start`).
3. **SSO region**: Enter the region where you enabled Identity Center (e.g., `us-east-1`).
4. A browser window will open. Log in with `hatan4ik@gmail.com`.
5. Allow the AWS CLI to access your data.
6. The CLI will prompt you to choose an account and a role (e.g., `AdministratorAccess`).
7. **CLI default client Region**: `us-east-1`
8. **CLI default output format**: `json`
9. **CLI profile name**: Name it `ses-admin`.

You can now run Terraform and AWS commands locally using this profile by exporting it:
```bash
export AWS_PROFILE=ses-admin
```

## Option B: Bootstrapping via a New IAM Access Key (Fallback)
The existing access key for `AWS-hatan4ik` in your `~/.aws/credentials` file is currently returning an `InvalidClientTokenId` error. If you need a new static key to bootstrap the environment before SSO is set up:

1. Log into the [AWS Management Console](https://console.aws.amazon.com/) using `hatan4ik@gmail.com`.
2. Navigate to the **IAM Dashboard** -> **Users**.
3. Select your user (e.g., `hatan4ik`).
4. Go to the **Security credentials** tab.
5. Under **Access keys**, click **Create access key** (select "CLI" as the use case).
6. Copy the new **Access Key ID** and **Secret Access Key**.
7. Open your terminal and run:
   ```bash
   aws configure --profile AWS-hatan4ik
   ```
8. Paste the new Access Key ID and Secret Access Key when prompted. Set the default region to `us-east-1` and output format to `json`.

Test your access by running:
```bash
aws sts get-caller-identity --profile AWS-hatan4ik
```

## Next Steps for Terraform
Once you have valid credentials configured, we can initialize the AWS provider in our root modules using your chosen profile.

