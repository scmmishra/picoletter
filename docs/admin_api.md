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

### HMAC Signature (for POST, PUT, PATCH requests)

For any request that modifies data, you must include an HMAC signature:

1. Generate a timestamp (Unix timestamp in seconds)
2. Create a signature using HMAC-SHA256 with the format: `timestamp:request_body`
3. Include both in your request headers:

```
X-HMAC-Timestamp: 1617293932
X-HMAC-Signature: computed_signature_here
```

The HMAC secret should be set in your environment variables as `ADMIN_API_HMAC_SECRET`.

## Endpoints

### List Users

```
GET /api/admin/users
```

Returns a list of all users with basic information.

### Get User Details

```
GET /api/admin/users/:id
```

Returns detailed information about a specific user, including their limits and additional data.

### Update User

```
PATCH /api/admin/users/:id
```

Update a user's status, limits, or additional data.

#### Request Body Example

```json
{
  "user": {
    "active": true,
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

# Get all users
def get_users():
    headers = {"X-API-Key": API_KEY}
    response = requests.get(f"{BASE_URL}/users", headers=headers)
    return response.json()

# Update user limits
def update_user(user_id, new_limits, active=True):
    headers = {"X-API-Key": API_KEY}

    # Prepare request data
    data = {
        "user": {
            "active": active,
            "limits": new_limits
        }
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
    response = requests.patch(
        f"{BASE_URL}/users/{user_id}",
        data=json_data,
        headers=headers
    )

    return response.json()
```

### cURL Example

```bash
# Get all users
curl -X GET "https://yourdomain.com/api/admin/users" \
  -H "X-API-Key: your_api_key"

# Update a user
TIMESTAMP=$(date +%s)
PAYLOAD='{"user":{"active":true,"limits":{"subscriber_limit":5000}}}'
SIGNATURE=$(echo -n "${TIMESTAMP}:${PAYLOAD}" | openssl dgst -sha256 -hmac "your_hmac_secret" | cut -d ' ' -f 2)

curl -X PATCH "https://yourdomain.com/api/admin/users/1" \
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
