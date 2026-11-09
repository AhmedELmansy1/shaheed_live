/**
 * One-off Firestore Seeding Script for Match Score (config/app_settings)
 * Authenticated directly via the user's active Firebase CLI session.
 */
const fs = require('fs');
const path = require('path');
const os = require('os');
const { OAuth2Client } = require('google-auth-library');

const PROJECT_ID = 'shoot-bc845';
const BASE_FIRESTORE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// Helper to get a valid access token from Firebase CLI login store
async function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    throw new Error(`Firebase CLI session not found at ${configPath}. Please run 'firebase login' first.`);
  }

  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = config.tokens || config.user?.tokens;
  if (!tokens || !tokens.refresh_token) {
    throw new Error('No refresh token found in Firebase CLI session.');
  }

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

// Convert Firestore REST Value to plain JavaScript value
function firestoreValueToJs(val) {
  if (!val) return null;
  if ('stringValue' in val) return val.stringValue;
  if ('booleanValue' in val) return val.booleanValue;
  if ('integerValue' in val) return parseInt(val.integerValue, 10);
  if ('doubleValue' in val) return parseFloat(val.doubleValue);
  if ('mapValue' in val) {
    const res = {};
    const fields = val.mapValue.fields || {};
    for (const [k, v] of Object.entries(fields)) {
      res[k] = firestoreValueToJs(v);
    }
    return res;
  }
  if ('arrayValue' in val) {
    const values = val.arrayValue.values || [];
    return values.map(firestoreValueToJs);
  }
  if ('nullValue' in val) return null;
  return val;
}

// Convert plain JavaScript object to Firestore REST Document
function jsToFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    fields[key] = jsValueToFirestore(value);
  }
  return fields;
}

function jsValueToFirestore(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(jsValueToFirestore) } };
  }
  if (typeof val === 'object') {
    return { mapValue: { fields: jsToFirestoreFields(val) } };
  }
  return { stringValue: String(val) };
}

async function runSeed() {
  console.log('===============================================================');
  console.log(` Authenticating to Firebase Project: ${PROJECT_ID}`);
  console.log('===============================================================');

  const accessToken = await getAccessToken();
  console.log('✔ Successfully acquired OAuth2 access token from Firebase CLI session.\n');

  const docUrl = `${BASE_FIRESTORE_URL}/config/app_settings`;

  // 1. Read Current Document
  console.log('---------------------------------------------------------------');
  console.log(' [1] Reading current config/app_settings from Firestore...');
  console.log('---------------------------------------------------------------');

  const getRes = await fetch(docUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  let existingData = {};
  if (getRes.status === 200) {
    const rawDoc = await getRes.json();
    const fields = rawDoc.fields || {};
    for (const [k, v] of Object.entries(fields)) {
      existingData[k] = firestoreValueToJs(v);
    }
    console.log('Current Document Found:');
    console.log(JSON.stringify(existingData, null, 2));
  } else if (getRes.status === 404) {
    console.log('Document does not exist yet. Will create new.');
  } else {
    const errText = await getRes.text();
    throw new Error(`Failed to read document (${getRes.status}): ${errText}`);
  }

  // 2. Prepare Payload (Merging)
  console.log('\n---------------------------------------------------------------');
  console.log(' [2] Merging fields into config/app_settings...');
  console.log('---------------------------------------------------------------');

  const updateFields = {
    latest_app_version: '1.0.0',
    min_supported_version: '1.0.0',
    update_download_url: 'https://example.com/download',
    api_base_url_override: '',
    ad_config: {
      banner_home: {
        enabled: true,
        ad_unit_id: 'ca-app-pub-3940256099942544/6300978111',
      },
      banner_match_details: {
        enabled: true,
        ad_unit_id: 'ca-app-pub-3940256099942544/6300978111',
      },
      interstitial_match_open: {
        enabled: true,
        ad_unit_id: 'ca-app-pub-3940256099942544/1033173712',
        frequency_cap: 3,
      },
      native_match_list: {
        enabled: true,
        ad_unit_id: 'ca-app-pub-3940256099942544/2247696110',
        insert_every_n_items: 5,
      },
      app_open_ad: {
        enabled: true,
        ad_unit_id: 'ca-app-pub-3940256099942544/9257395921',
      },
      rewarded_ad: {
        enabled: false,
        ad_unit_id: 'ca-app-pub-3940256099942544/5224354917',
      },
    },
  };

  // Build field mask params so we only update/merge the specified fields, preserving force_update or other existing fields
  const fieldMaskParams = Object.keys(updateFields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');

  const patchUrl = `${docUrl}?${fieldMaskParams}`;
  const firestoreDocPayload = {
    fields: jsToFirestoreFields(updateFields),
  };

  const patchRes = await fetch(patchUrl, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(firestoreDocPayload),
  });

  if (!patchRes.ok) {
    const errText = await patchRes.text();
    throw new Error(`Failed to patch document (${patchRes.status}): ${errText}`);
  }

  console.log('✔ Successfully merged update payload into config/app_settings.');

  // 3. Read Back & Verify Final Document
  console.log('\n---------------------------------------------------------------');
  console.log(' [3] Reading back final document from Firestore...');
  console.log('---------------------------------------------------------------');

  const verifyRes = await fetch(docUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!verifyRes.ok) {
    throw new Error(`Failed to verify document (${verifyRes.status})`);
  }

  const finalRawDoc = await verifyRes.json();
  const finalFields = finalRawDoc.fields || {};
  const finalData = {};
  for (const [k, v] of Object.entries(finalFields)) {
    finalData[k] = firestoreValueToJs(v);
  }

  console.log('FINAL config/app_settings document in Firestore:');
  console.log(JSON.stringify(finalData, null, 2));
  console.log('\n===============================================================');
  console.log(' Seeding completed successfully!');
  console.log('===============================================================');
}

runSeed().catch((err) => {
  console.error('\n❌ Execution failed:', err.message);
  process.exit(1);
});
