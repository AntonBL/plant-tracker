# Plant Tracker - GCP Deployment Guide

## Prerequisites

1. Google Cloud account with billing enabled
2. `gcloud` CLI installed and authenticated
3. Gemini API key from Google AI Studio

## Step 1: Set Up GCP Project

```bash
# Set your project ID (replace with your actual project ID)
export PROJECT_ID="your-project-id"

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

## Step 2: Store Gemini API Key in Secret Manager

```bash
# Create secret (replace YOUR_API_KEY with your actual key)
echo "YOUR_API_KEY" | gcloud secrets create gemini-api-key --data-file=-

# Grant Cloud Functions access to the secret
gcloud secrets add-iam-policy-binding gemini-api-key \
    --member="serviceAccount:plant-tracker-ai@plant-tracker-482614.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

## Step 3: Deploy Cloud Function

```bash
# Navigate to server directory
cd server/

# Deploy the function
gcloud functions deploy plant-proxy \
  --gen2 \
  --runtime=python312 \
  --region=us-central1 \
  --trigger-http \
  --allow-unauthenticated \
  --service-account=plant-tracker-ai@plant-tracker-482614.iam.gserviceaccount.com \
  --entry-point=handle \
  --set-secrets=GEMINI_API_KEY=gemini-api-key:latest \
  --set-env-vars=GEMINI_MODEL=gemini-3-flash-preview,MAX_IMAGE_BYTES=5242880 \
  --memory=512Mi \
  --timeout=60s
```

## Step 4: Get the Function URL

```bash
# Get the function URL
gcloud functions describe plant-proxy --gen2 --region=us-central1 --format="value(serviceConfig.uri)"
```

Copy this URL - you'll need it for the iOS app configuration.

https://plant-proxy-ozg2qzyl6q-uc.a.run.app

## Step 5: Test the Deployment

```bash
# Test the /analyze endpoint (replace FUNCTION_URL with your actual URL)

 echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" > /tmp/test_b64.txt

curl -X POST https://plant-proxy-ozg2qzyl6q-uc.a.run.app/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "image_base64": \"$(cat /tmp/test_b64.txt)\",
    "plant_name": "Test Plant",
    "species": "Test Species"
  }'
```

## Environment Variables

The Cloud Function supports these environment variables:

- `GEMINI_API_KEY` (from Secret Manager) - Your Gemini API key
- `GEMINI_MODEL` (default: `gemini-3-flash-preview`) - The Gemini model to use
- `MAX_IMAGE_BYTES` (default: 5MB) - Maximum image size in bytes

## Monitoring

View logs:
```bash
gcloud functions logs read plant-proxy --gen2 --region=us-central1 --limit=50
```

## Updating the Function

When you make changes to the server code:

```bash
cd server/
gcloud functions deploy plant-proxy \
  --gen2 \
  --runtime=python312 \
  --region=us-central1 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=handle \
  --set-secrets=GEMINI_API_KEY=gemini-api-key:latest \
  --set-env-vars=GEMINI_MODEL=gemini-3-flash-preview
```

## Cost Optimization

- The function is set to 512Mi memory - adjust if needed
- Uses --allow-unauthenticated for simplicity; consider adding auth for production
- Gemini 3 Flash Preview is cost-effective for this use case

## Troubleshooting

**Error: "Secret not found"**
- Ensure the secret exists: `gcloud secrets list`
- Check IAM permissions on the secret

**Error: "Function deployment failed"**
- Check the build logs: `gcloud builds list --limit=1`
- Verify requirements.txt is correct

**Error: "Timeout during function execution"**
- Increase timeout: add `--timeout=120s` to deploy command
- Check Gemini API response times in logs
