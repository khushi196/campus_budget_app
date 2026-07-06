# Campus Budget AWS Backend

This folder turns the student budget app into a cloud-backed product:

- Cognito handles student sign up, email confirmation, and login.
- API Gateway exposes authenticated HTTP endpoints.
- Lambda stores and reads each user's budget snapshot.
- DynamoDB stores the app data per user.
- Systems Manager Parameter Store keeps the Gemini API key off the frontend.

The local C++ backend is still important for the OOP project showcase. The AWS backend is the production/cloud layer for real users.

## Files

| File | Purpose |
|------|---------|
| `template.yaml` | AWS SAM infrastructure template |
| `lambda/src/app.py` | Lambda handler for snapshot storage, report summary, and AI proxy |
| `lambda/tests/test_app.py` | Unit tests for the Lambda API behavior |

## API Routes

All app routes except `/health` expect a Cognito JWT in the `Authorization` header:

```text
Authorization: Bearer <id-token>
```

| Method | Route | Purpose |
|--------|-------|---------|
| `GET` | `/health` | API smoke test |
| `GET` | `/snapshot` | Load the signed-in student's full budget data |
| `PUT` | `/snapshot` | Save the signed-in student's full budget data |
| `GET` | `/reports/summary` | Return totals for dashboard/report views |
| `POST` | `/ai/gemini` | Server-side Gemini proxy |

## Local Lambda Tests

Run from the project root:

```powershell
python aws\lambda\tests\test_app.py
```

## Store Gemini Key Safely

Do this once before deploying:

```powershell
aws ssm put-parameter `
  --name /campus-budget/gemini-api-key `
  --type SecureString `
  --value "YOUR_GEMINI_KEY" `
  --overwrite
```

Never put the Gemini key in Flutter code. The frontend calls `/ai/gemini`; Lambda reads the key from Parameter Store.

## Deploy

Prerequisites:

- AWS CLI configured with your account
- AWS SAM CLI installed
- Python 3.12 available

Deploy:

```powershell
cd "C:\Users\Khushi Prashad\campus_budget_app\aws"
.\deploy.ps1
```

The script asks for your Gemini API key, saves it in Parameter Store, deploys the AWS stack, and writes the API/Cognito values into the project `.env` file.

After deploy, run the app with:

```powershell
cd "C:\Users\Khushi Prashad\campus_budget_app"
.\run_web.ps1
```

Build for web with:

```powershell
.\build_web.ps1
```

Manual deploy:

```powershell
cd aws
sam build
sam deploy --guided
```

After deployment, copy these outputs:

- `ApiUrl`
- `AwsRegion`
- `UserPoolClientId`

## Build Flutter for the AWS API

The easy way from the project root:

```powershell
.\build_web.ps1
```

If you did not use `deploy.ps1`, copy `.env.example` to `.env` and fill in the actual output values from `sam deploy`.

## Flutter Cloud Client Files

| File | Purpose |
|------|---------|
| `lib/services/aws_config.dart` | Reads AWS build-time configuration |
| `lib/services/aws_auth_service.dart` | Cognito sign up, confirm, and sign in |
| `lib/services/aws_budget_api.dart` | Authenticated calls to the AWS API |
| `lib/services/aws_expense_store.dart` | ExpenseStore implementation backed by AWS |

## Still Left Before Launch

- Store the `AwsSession` securely for browser refreshes.
- Deploy Flutter web to S3 + CloudFront or another static host.
- Add stronger validation/rate limits before public launch.
