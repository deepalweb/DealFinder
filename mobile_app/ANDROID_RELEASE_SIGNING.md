# Android Release Signing

This app now requires real Android signing credentials for `flutter build appbundle`.

## 1. Create an upload keystore

Run this from the repo root or any secure local folder:

```powershell
keytool -genkeypair `
  -v `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload `
  -keystore .\mobile_app\android\keystore\dealfinder-upload-keystore.jks
```

Recommended:

- Use a strong store password
- Use a strong key password
- Save both in your team's password manager
- Back up the keystore file securely

## 2. Create `mobile_app/android/key.properties`

Copy `mobile_app/android/key.properties.example` to `mobile_app/android/key.properties` and fill it in:

```properties
storeFile=keystore/dealfinder-upload-keystore.jks
storePassword=your-store-password
keyAlias=upload
keyPassword=your-key-password
```

Important:

- `storeFile` is resolved relative to `mobile_app/android/`
- Do not commit `key.properties`
- Do not commit the keystore file

## 3. Add the SHA fingerprints to Firebase

After the keystore is created, run:

```powershell
keytool -list -v `
  -alias upload `
  -keystore .\mobile_app\android\keystore\dealfinder-upload-keystore.jks
```

Copy the `SHA1` and `SHA256` values into the Android app entry in Firebase Console, then download a fresh `google-services.json`.

## 4. Build the Play Store bundle

From `mobile_app/`:

```powershell
flutter clean
flutter pub get
flutter build appbundle
```

Expected output:

- `mobile_app/build/app/outputs/bundle/release/app-release.aab`

## 5. Play Console setup

- Create the app in Google Play Console
- Enroll in Play App Signing
- Upload the generated `.aab`
- Save the upload key details securely for future releases

## CI option

Instead of `key.properties`, CI can provide these environment variables:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

If you use CI, make sure the keystore file also exists at the referenced path during the build.
