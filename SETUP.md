# Bedrock Setup Guide

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `bedrock`
3. Description: "Unix-like kernel for Roblox OS emulation"
4. Visibility: Public (or Private if preferred)
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## Step 2: Push Bedrock to GitHub

```bash
cd c:\Users\Majhool\dev\bedrock

# Add all files
git add -A

# Commit
git commit -m "Initial commit: Bedrock kernel v1.0

- Core: VFS, Scheduler, Heap, Bootstrap, LuaVM
- HAL: GPU, HID, RAM, Network  
- Syscalls: FileSystem, Process, Hardware, Network, Library
- Documentation: README, ARCHITECTURE, API reference
- Configuration: LICENSE, CHANGELOG, .gitignore, .luaurc"

# Add remote (replace with your actual GitHub URL)
git remote add origin https://github.com/gado7h/bedrock.git

# Push to GitHub
git push -u origin main
```

## Step 3: Add Bedrock as Submodule to PremiumOS

```bash
cd c:\Users\Majhool\dev\PremiumOS

# Add as submodule
git submodule add https://github.com/gado7h/bedrock.git bedrock

# Initialize submodule
git submodule update --init --recursive

# Verify it worked
ls bedrock/Kernel  # Should show kernel files
```

## Step 4: Test Integration

```bash
# Run tests
aether run

# Expected: All 48 tests should pass
```

## Step 5: Clean Up Old Kernel

```bash
# Remove old kernel directory
rm -r src/client/Kernel

# Commit changes
git add -A
git commit -m "Migrate Kernel to bedrock submodule

- Removed src/client/Kernel (now in bedrock)
- Updated Boot.client.luau to use ReplicatedStorage.Kernel
- Updated default.project.json to reference bedrock submodule"

# Push to GitHub
git push
```

## Troubleshooting

### "fatal: repository not found"
- Make sure you created the GitHub repository first
- Verify the URL is correct: `https://github.com/gado7h/bedrock.git`

### "Kernel is not a valid member of ReplicatedStorage"
- Make sure you ran `git submodule update --init`
- Verify `bedrock/Kernel` directory exists
- Check `default.project.json` points to `bedrock/Kernel`

### Tests fail after migration
- Ensure all 32 kernel files are in `bedrock/Kernel`
- Verify `Boot.client.luau` uses `ReplicatedStorage.Kernel`
- Check Rojo can find the bedrock directory

## Future Updates

### Update Bedrock
```bash
cd c:\Users\Majhool\dev\bedrock
# Make changes...
git add -A
git commit -m "Update: description"
git push
```

### Pull Bedrock Updates in PremiumOS
```bash
cd c:\Users\Majhool\dev\PremiumOS
git submodule update --remote bedrock
git add bedrock
git commit -m "Update bedrock to latest version"
git push
```
