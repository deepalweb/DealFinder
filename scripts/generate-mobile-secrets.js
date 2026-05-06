const fs = require('fs');
const path = require('path');

const root = process.cwd();
const mobileRoot = path.join(root, 'mobile_app');

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function writeFileIfContent(filePath, content, label) {
  if (!content || !content.trim()) {
    return false;
  }

  ensureDir(filePath);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`Wrote ${label}: ${path.relative(root, filePath)}`);
  return true;
}

function readEnv(name) {
  const value = process.env[name];
  return typeof value === 'string' ? value.trim() : '';
}

function decodeMaybeBase64(name) {
  const value = readEnv(name);
  if (!value) return '';
  return Buffer.from(value, 'base64').toString('utf8');
}

function xmlEscape(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

function reverseClientId(clientId) {
  return clientId.split('.').reverse().join('.');
}

function buildDotEnv() {
  const pairs = [
    ['MOBILE_API_BASE_URL', readEnv('MOBILE_API_BASE_URL')],
    ['MOBILE_PUBLIC_BASE_URL', readEnv('MOBILE_PUBLIC_BASE_URL')],
    ['BACKEND_URL', readEnv('BACKEND_URL')],
    ['GOOGLE_WEB_CLIENT_ID', readEnv('GOOGLE_WEB_CLIENT_ID')],
    ['GOOGLE_MAPS_API_KEY', readEnv('GOOGLE_MAPS_API_KEY')],
  ].filter(([, value]) => value);

  if (!pairs.length) return '';
  return `${pairs.map(([key, value]) => `${key}=${value}`).join('\n')}\n`;
}

function buildAndroidGoogleServicesJson() {
  const values = {
    projectNumber: readEnv('FIREBASE_PROJECT_NUMBER'),
    projectId: readEnv('FIREBASE_PROJECT_ID'),
    storageBucket: readEnv('FIREBASE_STORAGE_BUCKET'),
    androidAppId: readEnv('FIREBASE_ANDROID_APP_ID'),
    androidPackageName:
      readEnv('FIREBASE_ANDROID_PACKAGE_NAME') ||
      'com.dealfinder.mobile',
    webClientId: readEnv('GOOGLE_WEB_CLIENT_ID'),
    androidApiKey:
      readEnv('GOOGLE_ANDROID_API_KEY') || readEnv('GOOGLE_API_KEY'),
    iosClientId: readEnv('GOOGLE_IOS_CLIENT_ID'),
    iosBundleId:
      readEnv('FIREBASE_IOS_BUNDLE_ID') || 'com.example.dealFinderMobile',
  };

  if (
    !values.projectNumber ||
    !values.projectId ||
    !values.storageBucket ||
    !values.androidAppId ||
    !values.webClientId ||
    !values.androidApiKey
  ) {
    return '';
  }

  const payload = {
    project_info: {
      project_number: values.projectNumber,
      project_id: values.projectId,
      storage_bucket: values.storageBucket,
    },
    client: [
      {
        client_info: {
          mobilesdk_app_id: values.androidAppId,
          android_client_info: {
            package_name: values.androidPackageName,
          },
        },
        oauth_client: [
          {
            client_id: values.webClientId,
            client_type: 3,
          },
        ],
        api_key: [
          {
            current_key: values.androidApiKey,
          },
        ],
        services: {
          appinvite_service: {
            other_platform_oauth_client: [
              {
                client_id: values.webClientId,
                client_type: 3,
              },
              ...(values.iosClientId
                ? [
                    {
                      client_id: values.iosClientId,
                      client_type: 2,
                      ios_info: {
                        bundle_id: values.iosBundleId,
                      },
                    },
                  ]
                : []),
            ],
          },
        },
      },
    ],
    configuration_version: '1',
  };

  return `${JSON.stringify(payload, null, 2)}\n`;
}

function buildIosGoogleServiceInfoPlist() {
  const values = {
    apiKey: readEnv('GOOGLE_IOS_API_KEY') || readEnv('GOOGLE_API_KEY'),
    gcmSenderId: readEnv('FIREBASE_PROJECT_NUMBER'),
    projectId: readEnv('FIREBASE_PROJECT_ID'),
    storageBucket: readEnv('FIREBASE_STORAGE_BUCKET'),
    googleAppId: readEnv('FIREBASE_IOS_APP_ID'),
    bundleId:
      readEnv('FIREBASE_IOS_BUNDLE_ID') || 'com.example.dealFinderMobile',
    clientId: readEnv('GOOGLE_IOS_CLIENT_ID'),
  };

  if (
    !values.apiKey ||
    !values.gcmSenderId ||
    !values.projectId ||
    !values.storageBucket ||
    !values.googleAppId ||
    !values.clientId
  ) {
    return '';
  }

  const reversedClientId = reverseClientId(values.clientId);

  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>API_KEY</key>
  <string>${xmlEscape(values.apiKey)}</string>
  <key>GCM_SENDER_ID</key>
  <string>${xmlEscape(values.gcmSenderId)}</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>${xmlEscape(values.bundleId)}</string>
  <key>PROJECT_ID</key>
  <string>${xmlEscape(values.projectId)}</string>
  <key>STORAGE_BUCKET</key>
  <string>${xmlEscape(values.storageBucket)}</string>
  <key>IS_ADS_ENABLED</key>
  <false/>
  <key>IS_ANALYTICS_ENABLED</key>
  <false/>
  <key>IS_APPINVITE_ENABLED</key>
  <true/>
  <key>IS_GCM_ENABLED</key>
  <true/>
  <key>IS_SIGNIN_ENABLED</key>
  <true/>
  <key>GOOGLE_APP_ID</key>
  <string>${xmlEscape(values.googleAppId)}</string>
  <key>CLIENT_ID</key>
  <string>${xmlEscape(values.clientId)}</string>
  <key>REVERSED_CLIENT_ID</key>
  <string>${xmlEscape(reversedClientId)}</string>
</dict>
</plist>
`;
}

function buildIosMapsConfig() {
  const key = readEnv('GOOGLE_MAPS_API_KEY');
  if (!key) return '';
  return `GOOGLE_MAPS_API_KEY=${key}\n`;
}

function buildAndroidSecretsProperties() {
  const key = readEnv('GOOGLE_MAPS_API_KEY');
  if (!key) return '';
  return `GOOGLE_MAPS_API_KEY=${key}\n`;
}

function main() {
  const outputs = [
    {
      label: '.env',
      filePath: path.join(mobileRoot, '.env'),
      direct:
        decodeMaybeBase64('MOBILE_APP_ENV_BASE64') ||
        readEnv('MOBILE_APP_ENV_CONTENT'),
      fallback: buildDotEnv(),
    },
    {
      label: 'Android google-services.json',
      filePath: path.join(mobileRoot, 'android', 'app', 'google-services.json'),
      direct:
        decodeMaybeBase64('GOOGLE_SERVICES_JSON_BASE64') ||
        readEnv('GOOGLE_SERVICES_JSON_CONTENT'),
      fallback: buildAndroidGoogleServicesJson(),
    },
    {
      label: 'iOS GoogleService-Info.plist',
      filePath: path.join(
        mobileRoot,
        'ios',
        'Runner',
        'GoogleService-Info.plist',
      ),
      direct:
        decodeMaybeBase64('GOOGLE_SERVICE_INFO_PLIST_BASE64') ||
        readEnv('GOOGLE_SERVICE_INFO_PLIST_CONTENT'),
      fallback: buildIosGoogleServiceInfoPlist(),
    },
    {
      label: 'iOS MapsConfig.xcconfig',
      filePath: path.join(mobileRoot, 'ios', 'Flutter', 'MapsConfig.xcconfig'),
      direct: '',
      fallback: buildIosMapsConfig(),
    },
    {
      label: 'Android secrets.properties',
      filePath: path.join(mobileRoot, 'android', 'secrets.properties'),
      direct: '',
      fallback: buildAndroidSecretsProperties(),
    },
  ];

  const written = outputs
    .map((item) =>
      writeFileIfContent(
        item.filePath,
        item.direct || item.fallback,
        item.label,
      ),
    )
    .filter(Boolean).length;

  if (!written) {
    console.log(
      'No mobile secret files were generated. Set the required environment variables and run the script again.',
    );
    process.exitCode = 1;
  }
}

main();
