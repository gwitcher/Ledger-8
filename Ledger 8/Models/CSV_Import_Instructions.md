# CSV Import System for Ledger 8

## 🎯 Overview
The CSV import system has been specifically configured to work with your `ledger_analytics_2025.csv` file format. It will automatically detect and import your data, creating Projects, Items, and Clients as needed.

## 📊 Your CSV Format
Your CSV file with columns: `Project, Artist, Client, Date, Media Type, Income, Paid`

The system will:
- Create **Projects** for each unique Project + Artist combination
- Create **Items** for each income entry
- Create **Clients** from the Client column
- Link everything together automatically
- Set payment status based on the "Paid" column

## 🚀 How to Use

### Step 1: Access the Import Feature
Go to **Settings** → **Data Management** → **Import CSV Data**

### Step 2: Select Your CSV File
- Tap "Select CSV File"
- Choose your `ledger_analytics_2025.csv` file
- The system will automatically detect it as "Ledger Analytics" format

### Step 3: Import Process
- The importer will process 53 projects from your CSV
- It will create unique projects for each Project/Artist combination
- Each income entry becomes an Item linked to its project
- Clients are created and linked automatically
- Progress is shown in real-time

## 📋 What Gets Created

### Projects Created:
- **Project Name**: From "Project" column
- **Artist**: From "Artist" column  
- **Start/End Date**: From "Date" column
- **Media Type**: Mapped from your "Media Type" values
- **Status**: "Paid" if Paid=Yes, "Open" if Paid=No
- **Client**: Linked to created client

### Items Created:
- **Name**: Uses project name or "Service"
- **Fee**: From "Income" column
- **Item Type**: Mapped based on Media Type
- **Project**: Linked to corresponding project

### Clients Created:
- **Company/Name**: From "Client" column
- Automatically deduplicated

## 🔄 Media Type Mapping
Your CSV values → App values:
- "Film" → Film
- "TV" → TV  
- "Recording" → Recording
- "Concert" → Concert
- "Tour" → Tour
- "Other" → Other

## ✅ Data Summary from Your CSV
- **Total Entries**: 53
- **Total Income**: $124,556.12
- **Paid Income**: $119,756.12
- **Unpaid Income**: $4,800.00

## 🛠️ Technical Notes
- Summary lines are automatically filtered out
- Duplicate projects/clients are avoided
- Date parsing supports multiple formats
- Progress tracking and error handling included
- All data is validated before insertion

## 📱 Integration Complete
The CSV import button has been added to your existing SettingsView under "Data Management".

Ready to import your data! 🎉