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

echo
echo "=== OPTION A: Safe Cleanup Implementation ==="
echo "Running safe cleanup approach..."
echo

# Step 1: Commit .gitignore first
echo "Step 1: Adding and committing .gitignore file..."
git add .gitignore
git commit -m "Add .gitignore file for Swift project"

echo
echo "Step 2: Removing problematic files safely..."

# Remove .DS_Store files if they exist
echo "Checking for .DS_Store files..."
if git ls-files | grep -q "\.DS_Store"; then
    echo "Removing .DS_Store files..."
    find . -name .DS_Store -print0 | xargs -0 git rm --ignore-unmatch --cached
else
    echo "No .DS_Store files found in tracking."
fi

# Remove xcuserdata directories if they exist
echo "Checking for xcuserdata directories..."
if git ls-files | grep -q "xcuserdata"; then
    echo "Removing xcuserdata directories..."
    git rm -r --cached */xcuserdata/ 2>/dev/null || true
    git rm -r --cached */*/xcuserdata/ 2>/dev/null || true
    git rm -r --cached */*/*/xcuserdata/ 2>/dev/null || true
else
    echo "No xcuserdata directories found in tracking."
fi

# Remove build directories if they exist
echo "Checking for build artifacts..."
BUILD_FOUND=false
if git ls-files | grep -q "build/\|DerivedData/\|\.build/"; then
    BUILD_FOUND=true
    echo "Removing build artifacts..."
    git rm -r --cached build/ 2>/dev/null || true
    git rm -r --cached DerivedData/ 2>/dev/null || true
    git rm -r --cached .build/ 2>/dev/null || true
else
    echo "No build artifacts found in tracking."
fi

# Remove temporary files if they exist
echo "Checking for temporary files..."
if git ls-files | grep -q "\.log\|\.tmp\|\.temp"; then
    echo "Removing temporary files..."
    git rm --cached *.log 2>/dev/null || true
    git rm --cached *.tmp 2>/dev/null || true
    git rm --cached *.temp 2>/dev/null || true
else
    echo "No temporary files found in tracking."
fi

echo
echo "Step 3: Committing cleanup changes..."
git commit -m "Remove unwanted files from Git tracking (safe cleanup)"

echo
echo "Step 4: Checking final status..."
git status

echo
echo "=== Cleanup Complete! ==="
echo "You can now push your changes with: git push origin main"
echo "(Replace 'main' with your branch name if different)"