# Version Management System

This project now includes a centralized version management system to ensure consistent tool versions across deployments.

## Files Added/Modified

### 1. `version-config.sh` - Centralized Configuration
- Contains all version requirements in one place
- Provides helper functions for version management
- Used by setup and check scripts

### 2. `version-manager.sh` - Version Management Tool
- Interactive tool for updating version requirements
- Checks latest versions online
- Updates both configuration and Terraform constraints

### 3. Updated Scripts
- `setup-execution-machine.sh` - Now uses centralized config
- `check-dependencies.sh` - Now uses centralized config
- `terraform/version.tf` - Updated to require Terraform >= 1.12.2

## Current Version Requirements

- **Terraform**: 1.12.2 (latest stable)
- **AWS CLI**: 2.0.0 (minimum v2.x)
- **Ansible**: 6.0.0 (minimum)
- **Python**: 3.8 (minimum)
- **Ubuntu**: 22.04 (minimum)

## Usage

### Check Current Versions
```bash
./version-manager.sh show
```

### Check Latest Available Versions
```bash
./version-manager.sh check
```

### Update a Tool Version
```bash
./version-manager.sh update terraform 1.12.3
./version-manager.sh update aws-cli 2.15.0
./version-manager.sh update ansible 6.1.0
```

### Run Setup with New Versions
```bash
./setup-execution-machine.sh
```

## Benefits

1. **Centralized Management**: All version requirements in one file
2. **Consistency**: All scripts use the same version source
3. **Easy Updates**: Single command to update version requirements
4. **Automatic Constraint Updates**: Terraform constraints updated automatically
5. **Version Validation**: Proper version format checking
6. **Online Check**: Ability to check latest versions

## Implementation Details

The setup script (`setup-execution-machine.sh`) now:
- Sources version requirements from `version-config.sh`
- Enforces exact Terraform version (1.12.2)
- Downloads and installs the specified version if mismatch
- Validates installation after completion

The check script (`check-dependencies.sh`) now:
- Uses centralized version requirements
- Provides consistent version checking
- Reports version mismatches clearly

## Making Scripts Executable (Linux/Ubuntu)

When running on Linux/Ubuntu, make sure to set execute permissions:
```bash
chmod +x version-config.sh
chmod +x version-manager.sh
chmod +x setup-execution-machine.sh
chmod +x check-dependencies.sh
```

## Cross-Platform Compatibility

The scripts are designed to work on both Windows (with Git Bash/WSL) and Ubuntu Linux environments. Version management remains consistent across platforms.

## Troubleshooting

If you encounter version issues:
1. Run `./version-manager.sh check` to see current vs required versions
2. Run `./setup-execution-machine.sh` to install/update to required versions
3. Check `version-config.sh` to modify requirements if needed

## Future Enhancements

The version management system can be extended to:
- Support additional tools (Docker, kubectl, etc.)
- Add checksums for security validation
- Support multiple architecture downloads
- Integration with CI/CD pipelines
