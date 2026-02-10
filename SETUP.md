# Bedrock Setup Guide

### Option A: GitHub Releases (Recommended)
Download the latest `Bedrock.rbxm` from the [Releases](https://github.com/gado7h/bedrock/releases) page and insert it into your project.

### Option B: Git Submodule
If you want to track the latest development version:

```bash
git submodule add https://github.com/gado7h/bedrock.git packages/bedrock
```

## Step 2: Configure Project (Rojo)

Update your `default.project.json` to map the Bedrock source files into `ReplicatedStorage`.

```json
{
  "name": "MyDistro",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Bedrock": {
        "$path": "packages/bedrock/src"
      },
      "MyDistro": {
        "$path": "src/Client"
      }
    },
    "ServerScriptService": {
      "BedrockHost": {
        "$path": "packages/bedrock/src/Server"
      }
    }
  }
}
```

## Step 3: Create your Distribution

See [docs/DISTRIBUTIONS.md](docs/DISTRIBUTIONS.md) for a comprehensive guide on creating your first distribution manifest.

## Step 4: Run it!

1.  Sync your project with Rojo.
2.  Start a Local Server in Roblox Studio.
3.  Check the Output window for "Kernel Initialization Complete".

