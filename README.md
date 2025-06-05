# ⚡ Purkinje Terraform Automation

Este proyecto automatiza la creación y uso de una máquina virtual en Google Cloud Platform (GCP) para ejecutar un _notebook_ de optimización bayesiana sobre la red de Purkinje.

Utiliza **Terraform**, **Docker**, y **GitHub Actions** para levantar la infraestructura, ejecutar el experimento y subir los resultados a un bucket de GCS.

---

## 🚀 Cómo lanzar el experimento

1. Ve a [Actions > Deploy Purkinje VM](https://github.com/ricardogr07/purkinje-learning/actions/workflows/deploy.yml).
2. Haz clic en el botón `Run workflow`.

Esto:
- Levanta una VM en GCP.
- Ejecuta `ECG_BO_demo.ipynb` dentro de un contenedor Docker.
- Guarda la salida en GCS.
- Envía una notificación por correo.
- Apaga automáticamente la VM.

> 🔐 Asegúrate de que los _secrets_ `GOOGLE_CREDENTIALS` y `GMAIL_TOKEN_JSON` están configurados.

---

## 📦 Requisitos del notebook

El notebook debe estar preparado para ser ejecutado de forma autónoma con `nbconvert`, sin requerir interacción.

---

## 📤 Resultados

Los resultados se guardan en el bucket GCS configurado como `GCS_BUCKET`, e incluyen:

- `output.ipynb`: Notebook con celdas ejecutadas.
- `log.txt`: Log completo de la ejecución.
- Archivos adicionales generados en la carpeta `/output`.

---

## 📬 Notificación automática

Si `token.json` está presente, al finalizar la ejecución se envía un correo automático notificando que el experimento ha terminado.

---

## 🧹 Apagado automático

La VM se apaga automáticamente una vez que se suben los resultados.

---

## 🛠️ Terraform

El archivo `src/main.tf` define:
- La instancia `n2-standard-32`
- Disco con Ubuntu 22.04
- Script de arranque (`startup.sh`)
- Etiquetas y metadatos necesarios

Puedes probar manualmente:

```bash
cd src
terraform init
terraform plan -var="credentials_file=gcp-key.json"
terraform apply -var="credentials_file=gcp-key.json"
```

---

## 🧪 Créditos

Desarrollado por Ricardo García – [@ricardogr07](https://github.com/ricardogr07)