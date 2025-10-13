#!/bin/bash

# Git Repository Cleanup Script
# This script helps identify and fix common Git issues with ignored files

echo "=== Git Repository Status Check ==="
echo

echo "1. Current Git status:"
git status

echo
echo "2. Files currently being tracked:"
git ls-files

echo
echo "3. Files that should be ignored but might be tracked:"
echo "Checking for common problem files..."

# Check for common problematic files
if git ls-files | grep -q "\.DS_Store"; then
    echo "❌ Found .DS_Store files being tracked"
fi

if git ls-files | grep -q "xcuserdata"; then
    echo "❌ Found xcuserdata files being tracked"
fi

if git ls-files | grep -q "build/\|DerivedData/\|\.build/"; then
    echo "❌ Found build artifacts being tracked"
fi

if git ls-files | grep -q "\.log\|\.tmp\|\.temp"; then
    echo "❌ Found temporary files being tracked"
fi

echo
echo "=== Recommended Actions ==="
echo

echo "Option 1: Safe approach - Remove specific problem files"
echo "git rm --cached .DS_Store (if .DS_Store files exist)"
echo "git rm -r --cached */xcuserdata (if xcuserdata exists)"
echo "git rm -r --cached build/ DerivedData/ .build/ (if build dirs exist)"

echo
echo "Option 2: Complete reset approach (use with caution!)"
echo "git rm -r --cached ."
echo "git add ."
echo "git commit -m 'Clean up repository with proper .gitignore'"

echo
echo "Option 3: Just commit the .gitignore file first"
echo "git add .gitignore"
echo "git commit -m 'Add .gitignore file for Swift project'"