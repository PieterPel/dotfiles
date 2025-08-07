#!/bin/bash
# Manual script to update SOPS keys for all secrets

echo "🔑 Updating SOPS keys for all secret files..."

# Find all YAML files in secrets/ directory
if [ -d "secrets" ]; then
    failed_files=()
    find secrets -name "*.yaml" -o -name "*.yml" | while read -r file; do
        echo "Updating keys for: $file"
        if command -v nix-shell > /dev/null 2>&1; then
            # Auto-answer 'y' to prompts
            echo "y" | nix-shell -p sops --run "sops updatekeys '$file'" || {
                echo "⚠️  Failed to update keys for $file"
                failed_files+=("$file")
            }
        elif command -v sops > /dev/null 2>&1; then
            # Auto-answer 'y' to prompts  
            echo "y" | sops updatekeys "$file" || {
                echo "⚠️  Failed to update keys for $file"
                failed_files+=("$file")
            }
        else
            echo "❌ Neither nix-shell nor sops command found"
            exit 1
        fi
    done
    
    # Check if any files failed and report accordingly
    if [ ${#failed_files[@]} -eq 0 ]; then
        echo "✅ SOPS key update completed successfully"
    else
        echo "⚠️  SOPS key update completed with ${#failed_files[@]} failures"
    fi
else
    echo "❌ secrets/ directory not found"
    exit 1
fi
