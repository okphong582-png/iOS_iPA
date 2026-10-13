# Free Fire Mod Menu iOS (Container Injector)

This is a standalone ESP & Mod menu for Free Fire running on iOS (Jailbroken / TrollStore).

## Features
- **ESP Name, ESP Line, ESP Box, ESP Distance, ESP Health, ESP Fov**
- **AimSystem** (Target Head, Neck, Body)
- **Silent Aim**
- **No Recoil**

## How it works
This iOS app syncs settings from the UI to `localConfig.json` and automatically injects it into the target game container `Documents/` path.
The mod patch `Assembly-CSharp-patch.bytes` will be downloaded from this repository directly upon injection.

## Usage
1. Build IPA or install via TrollStore.
2. Select target (Free Fire TH or MAX).
3. Toggle features on/off.
4. Click **Inject** to apply changes instantly to the game.

## Installation
Make sure to put the generated `Assembly-CSharp-patch.bytes` into the root of this repo, so the app can fetch it.
