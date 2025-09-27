#!/bin/bash
# Backup script for Ledger 8 SwiftData models
# Run this from project root directory

BACKUP_DIR="model_backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Copy all model files
cp Project.swift "$BACKUP_DIR/"
cp Client.swift "$BACKUP_DIR/"
cp Item.swift "$BACKUP_DIR/"
cp Invoice.swift "$BACKUP_DIR/"
cp Enums.swift "$BACKUP_DIR/"

# Create backup info
echo "Backup created on: $(date)" > "$BACKUP_DIR/backup_info.txt"
echo "Git commit: $(git rev-parse HEAD)" >> "$BACKUP_DIR/backup_info.txt"
echo "Git branch: $(git branch --show-current)" >> "$BACKUP_DIR/backup_info.txt"

echo "Model backup created in: $BACKUP_DIR"