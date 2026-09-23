const fs = require('fs');
const path = require('path');
const os = require('os');
const { OAuth2Client } = require('google-auth-library');

const PROJECT_ID = 'shoot-bc845';
const BASE_FIRESTORE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

async function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = config.tokens || config.user?.tokens;

  const oauth2Client = new OAuth2Client({
    clientId: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho859e1.apps.googleusercontent.com',
    clientSecret: 'j9iEnvXuRkclFlyeprisCESW',
  });

  oauth2Client.setCredentials({
    refresh_token: tokens.refresh_token,
    access_token: tokens.access_token,
  });

  const { token } = await oauth2Client.getAccessToken();
  return token;
}

async function updateConfig(fields) {
  const token = await getAccessToken();
  const docUrl = `${BASE_FIRESTORE_URL}/config/app_settings`;
  const fieldMaskParams = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');

  const patchFields = {};
  for (const [k, v] of Object.entries(fields)) {
    if (typeof v === 'string') patchFields[k] = { stringValue: v };
    else if (typeof v === 'boolean') patchFields[k] = { booleanValue: v };
  }

  const res = await fetch(`${docUrl}?${fieldMaskParams}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: patchFields }),
  });

  console.log('Update result status:', res.status);
  const verifyRes = await fetch(docUrl, { headers: { Authorization: `Bearer ${token}` } });
  const data = await verifyRes.json();
  console.log('Current Firestore document:');
  console.log(JSON.stringify(data.fields, null, 2));
}

updateConfig({
  latest_app_version: '9.9.9',
  force_update: true,
  min_supported_version: '1.0.0',
});
