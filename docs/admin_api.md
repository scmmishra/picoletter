# PicoLetter Admin API Documentation

This document outlines how to use the PicoLetter Admin API to manage users, their limits, and status.

## Prerequisites

The Admin API is only available when billing is enabled in your PicoLetter installation. Make sure `ENABLE_BILLING` is set to `true` in your environment configuration.

## Authentication

All API requests require authentication using an API key and HMAC signature verification for write operations.

### API Key

Include your API key in the request header:

```
X-API-Key: your_api_key
```

The API key should be set in your environment variables as `ADMIN_API_KEY`.

### HMAC Signature

For all API requests, you must include an HMAC signature:

1. Generate a timestamp (Unix timestamp in seconds)
2. Create a signature using HMAC-SHA256 with the format: `timestamp:request_body`
3. Include both in your request headers:

```
X-HMAC-Timestamp: 1617293932
X-HMAC-Signature: computed_signature_here
```

The HMAC secret should be set in your environment variables as `ADMIN_API_HMAC_SECRET`.

## Endpoints

PicoLetter provides two simple API endpoints for managing users:

### Update User Limits

```
POST /api/admin/users/update_limits
```

Updates a user's limits and additional data.

#### Request Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| email | string | **Required**. The email of the user to update |
| limits | object | Optional. Contains subscriber_limit and monthly_email_limit |
| additional_data | object | Optional. Any additional data to store with the user |

#### Request Body Example

```json
{
  "email": "user@example.com",
  "limits": {
    "subscriber_limit": 5000,
    "monthly_email_limit": 50000
  },
  "additional_data": {
    "subscription": {
      "plan": "premium",
      "expires_at": "2025-12-31"
    }
  }
}
```

#### Response Example

```json
{
  "success": true,
  "user": {
    "id": 123,
    "email": "user@example.com",
    "limits": {
      "subscriber_limit": 5000,
      "monthly_email_limit": 50000
    },
    "additional_data": {
      "subscription": {
        "plan": "premium",
        "expires_at": "2025-12-31"
      }
    }
  }
}
```

### Toggle User Active Status

```
POST /api/admin/users/toggle_active
```

Enables or disables a user account.

#### Request Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| email | string | **Required**. The email of the user to update |
| active | boolean | **Required**. Whether the account should be active (true) or disabled (false) |

#### Request Body Example

```json
{
  "email": "user@example.com",
  "active": false
}
```

#### Response Example

```json
{
  "success": true,
  "user": {
    "id": 123,
    "email": "user@example.com",
    "active": false
  }
}
```

## Example Usage

### Python Example

```python
import requests
import hmac
import hashlib
import time
import json

API_KEY = "your_api_key"
HMAC_SECRET = "your_hmac_secret"
BASE_URL = "https://yourdomain.com/api/admin"

# Update user limits
def update_user_limits(email, subscriber_limit=None, monthly_email_limit=None, additional_data=None):
    headers = {"X-API-Key": API_KEY}
    
    # Prepare request data
    data = {"email": email}
    
    if subscriber_limit or monthly_email_limit:
        data["limits"] = {}
        if subscriber_limit:
            data["limits"]["subscriber_limit"] = subscriber_limit
        if monthly_email_limit:
            data["limits"]["monthly_email_limit"] = monthly_email_limit
    
    if additional_data:
        data["additional_data"] = additional_data
    
    # Convert to JSON
    json_data = json.dumps(data)
    
    # Generate timestamp and signature
    timestamp = str(int(time.time()))
    signature_data = f"{timestamp}:{json_data}"
    signature = hmac.new(
        HMAC_SECRET.encode(),
        signature_data.encode(),
        hashlib.sha256
    ).hexdigest()
    
    # Add HMAC headers
    headers["X-HMAC-Timestamp"] = timestamp
    headers["X-HMAC-Signature"] = signature
    headers["Content-Type"] = "application/json"
    
    # Make request
    response = requests.post(
        f"{BASE_URL}/users/update_limits",
        data=json_data,
        headers=headers
    )
    
    return response.json()

# Toggle user active status
def toggle_user_active(email, active=True):
    headers = {"X-API-Key": API_KEY}
    
    # Prepare request data
    data = {
        "email": email,
        "active": active
    }
    
    # Convert to JSON
    json_data = json.dumps(data)
    
    # Generate timestamp and signature
    timestamp = str(int(time.time()))
    signature_data = f"{timestamp}:{json_data}"
    signature = hmac.new(
        HMAC_SECRET.encode(),
        signature_data.encode(),
        hashlib.sha256
    ).hexdigest()
    
    # Add HMAC headers
    headers["X-HMAC-Timestamp"] = timestamp
    headers["X-HMAC-Signature"] = signature
    headers["Content-Type"] = "application/json"
    
    # Make request
    response = requests.post(
        f"{BASE_URL}/users/toggle_active",
        data=json_data,
        headers=headers
    )
    
    return response.json()
```

### cURL Example

```bash
# Update user limits
TIMESTAMP=$(date +%s)
PAYLOAD='{"email":"user@example.com","limits":{"subscriber_limit":5000}}'
SIGNATURE=$(echo -n "${TIMESTAMP}:${PAYLOAD}" | openssl dgst -sha256 -hmac "your_hmac_secret" | cut -d ' ' -f 2)

curl -X POST "https://yourdomain.com/api/admin/users/update_limits" \
  -H "X-API-Key: your_api_key" \
  -H "X-HMAC-Timestamp: ${TIMESTAMP}" \
  -H "X-HMAC-Signature: ${SIGNATURE}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}"

# Toggle user active status
TIMESTAMP=$(date +%s)
PAYLOAD='{"email":"user@example.com","active":false}'
SIGNATURE=$(echo -n "${TIMESTAMP}:${PAYLOAD}" | openssl dgst -sha256 -hmac "your_hmac_secret" | cut -d ' ' -f 2)

curl -X POST "https://yourdomain.com/api/admin/users/toggle_active" \
  -H "X-API-Key: your_api_key" \
  -H "X-HMAC-Timestamp: ${TIMESTAMP}" \
  -H "X-HMAC-Signature: ${SIGNATURE}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}"
```

## Environment Variables

Make sure to set these environment variables on your server:

```
ADMIN_API_KEY=your_secure_api_key
ADMIN_API_HMAC_SECRET=your_secure_hmac_secret
