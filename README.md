# PurkinjeTerraform

**PurkinjeTerraform** is a fully automated deployment pipeline for running Bayesian optimization experiments on the Purkinje fiber network using a virtual machine (VM) on Google Cloud Platform (GCP). It leverages **Terraform**, **Docker**, and **GitHub Actions** to provision infrastructure, execute containerized Jupyter notebooks, and store results in a GCS bucket—completely hands-free.

---

## Features

- ✅ One-click deployment via GitHub Actions  
- 📓 Runs a Jupyter notebook (`ECG_BO_demo.ipynb`) inside a Docker container  
- ☁️ Stores output artifacts (executed notebook, logs, generated files) in a GCS bucket  
- 📧 Automatic email notification upon completion  
- 💻 Auto-shutdown of GCP VM to prevent billing overhead  
- ⚙️ Modular and infrastructure-as-code using Terraform (`n2-standard-32`, Ubuntu 22.04, etc.)

---

## Quickstart: Launch the Experiment

1. Navigate to **Actions > Deploy Purkinje VM**:  
   [GitHub Actions Workflow](https://github.com/ricardogr07/purkinje-terraform/actions/workflows/deploy.yml)

2. Click **"Run workflow"**

This will:

- Provision a new VM instance on GCP  
- Clone the project repository and spin up a Docker container  
- Run the notebook non-interactively using `nbconvert`  
- Upload the full results to the specified GCS bucket  
- Send an optional email notification (if credentials are present)  
- Shut down the VM after execution  

> ⚠️ **Note**: Secrets `GOOGLE_CREDENTIALS` and `GMAIL_TOKEN_JSON` must be set in your GitHub repo for cloud and email access.

---

## Notebook Requirements

The notebook (`ECG_BO_demo.ipynb`) must be **self-contained** and executable via:

```bash
jupyter nbconvert --to notebook --execute ECG_BO_demo.ipynb
```

No manual inputs, widgets, or GUI elements should be required.

---

## Output Artifacts

Results are automatically saved to the configured `GCS_BUCKET` and include:

- `output.ipynb`: Fully executed notebook  
- `log.txt`: Standard output and error logs  
- Any generated files saved to the `/output/` directory in the container

---

## Email Notifications

If a valid **Gmail API token** (`token.json`) is included, a notification email will be sent upon successful experiment completion.  
This is useful for long-running tasks.

---

## Auto Shutdown

To minimize cloud costs, the virtual machine **shuts down automatically** after the notebook finishes and results are uploaded.

---

## Manual Terraform Usage

You can launch the infrastructure manually using the Terraform CLI:

```bash
cd src
terraform init
terraform plan -var="credentials_file=gcp-key.json"
terraform apply -var="credentials_file=gcp-key.json"
```

Resources created include:

- `n2-standard-32` VM with attached SSD  
- Ubuntu 22.04 base image  
- Metadata and `startup.sh` boot script for headless execution

---

## Dependencies

- Terraform ≥ 1.3  
- Docker  
- Google Cloud SDK  

GitHub repository secrets:

- `GOOGLE_CREDENTIALS` – Service account credentials for GCP  
- `GMAIL_TOKEN_JSON` – Gmail API token for notifications

---

## Maintainer and Context

This project is maintained by **Ricardo García Ramírez** as part of a reproducible research pipeline for optimizing electrical activation across Purkinje-like networks. It integrates tightly with **Bayesian optimization workflows** and is intended for **scalable, cloud-native execution** of computational cardiac models.

---

## License

This repository is released under the **MIT License**.  
See the [LICENSE](LICENSE) file for details.
