#!/bin/bash

# Firebase Disaster Recovery Script - RTDB + Auth Only
# This script helps restore your Firebase Realtime Database and Auth data from backups

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FIREBASE_PROJECT_ID="your-project-id"
FIREBASE_DATABASE_URL="https://${FIREBASE_PROJECT_ID}-default-rtdb.firebaseio.com"
SERVICE_ACCOUNT_KEY="service-account.json"
BACKUP_DIR="firebase-backups"

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Firebase Disaster Recovery Tool      ║${NC}"
echo -e "${GREEN}║  RTDB + Auth                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq not found${NC}"
    echo "Install it with: sudo apt-get install jq (Ubuntu) or brew install jq (Mac)"
    exit 1
fi

# Authenticate with Firebase
authenticate_firebase() {
    if [ ! -f "$SERVICE_ACCOUNT_KEY" ]; then
        echo -e "${YELLOW}Service account key not found at: $SERVICE_ACCOUNT_KEY${NC}"
        read -p "Enter path to service account JSON: " SERVICE_ACCOUNT_KEY
    fi
    
    echo -e "${YELLOW}🔐 Authenticating with Firebase...${NC}"
    export GOOGLE_APPLICATION_CREDENTIALS="$SERVICE_ACCOUNT_KEY"
    
    # Login to Firebase
    firebase login --no-localhost 2>/dev/null || firebase login
    
    echo -e "${GREEN}✅ Authenticated successfully${NC}"
}

# Function to list available backups
list_backups() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}Available Backups${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}❌ No backup directory found${NC}"
        echo "Please run the GitHub Actions workflow first to create backups"
        return
    fi
    
    echo -e "\n${YELLOW}📊 Realtime Database Backups:${NC}"
    if [ -d "$BACKUP_DIR/rtdb" ] && [ "$(ls -A $BACKUP_DIR/rtdb 2>/dev/null)" ]; then
        ls -lh "$BACKUP_DIR/rtdb/"*.json | awk '{print $9, "(" $5 ")"}'
        echo "Total: $(ls -1 $BACKUP_DIR/rtdb/*.json 2>/dev/null | wc -l) backups"
    else
        echo "No RTDB backups found"
    fi
    
    echo -e "\n${YELLOW}👥 Auth Users Backups:${NC}"
    if [ -d "$BACKUP_DIR/auth" ] && [ "$(ls -A $BACKUP_DIR/auth 2>/dev/null)" ]; then
        ls -lh "$BACKUP_DIR/auth/"*.json | awk '{print $9, "(" $5 ")"}'
        echo "Total: $(ls -1 $BACKUP_DIR/auth/*.json 2>/dev/null | wc -l) backups"
    else
        echo "No Auth backups found"
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"
}

# Function to restore Realtime Database
restore_rtdb() {
    echo -e "\n${YELLOW}🔄 Restoring Realtime Database...${NC}"
    
    if [ ! -d "$BACKUP_DIR/rtdb" ] || [ ! "$(ls -A $BACKUP_DIR/rtdb 2>/dev/null)" ]; then
        echo -e "${RED}❌ No RTDB backups available${NC}"
        return
    fi
    
    echo -e "\nAvailable backups:"
    select BACKUP_FILE in "$BACKUP_DIR/rtdb/"*.json; do
        if [ -n "$BACKUP_FILE" ]; then
            break
        fi
    done
    
    echo -e "\n${BLUE}Selected backup: $(basename $BACKUP_FILE)${NC}"
    echo -e "Backup size: $(du -h $BACKUP_FILE | cut -f1)"
    echo -e "Backup date: $(stat -c %y $BACKUP_FILE | cut -d' ' -f1,2)"
    
    # Preview backup content
    echo -e "\n${YELLOW}Preview of backup content:${NC}"
    jq -C 'keys | .[:5]' "$BACKUP_FILE" 2>/dev/null || echo "Unable to preview"
    
    echo -e "\n${RED}⚠️  WARNING: This will overwrite your entire Realtime Database!${NC}"
    echo -e "${RED}All current data will be lost!${NC}"
    read -p "Type 'YES' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "YES" ]; then
        echo -e "${RED}Restore cancelled${NC}"
        return
    fi
    
    # Get access token
    ACCESS_TOKEN=$(gcloud auth application-default print-access-token 2>/dev/null || \
                   gcloud auth print-access-token)
    
    if [ -z "$ACCESS_TOKEN" ]; then
        echo -e "${RED}❌ Failed to get access token${NC}"
        return
    fi
    
    echo -e "${YELLOW}Uploading data to Firebase...${NC}"
    
    # Upload data
    RESPONSE=$(curl -X PUT \
        "$FIREBASE_DATABASE_URL/.json?auth=$ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d @"$BACKUP_FILE" \
        --silent \
        --write-out "\nHTTP_STATUS:%{http_code}")
    
    HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo -e "${GREEN}✅ Realtime Database restored successfully!${NC}"
    else
        echo -e "${RED}❌ Restore failed with status: $HTTP_STATUS${NC}"
        echo "$RESPONSE"
    fi
}

# Function to restore Auth users
restore_auth() {
    echo -e "\n${YELLOW}🔄 Restoring Firebase Auth Users...${NC}"
    
    if [ ! -d "$BACKUP_DIR/auth" ] || [ ! "$(ls -A $BACKUP_DIR/auth 2>/dev/null)" ]; then
        echo -e "${RED}❌ No Auth backups available${NC}"
        return
    fi
    
    echo -e "\nAvailable backups:"
    select BACKUP_FILE in "$BACKUP_DIR/auth/"*.json; do
        if [ -n "$BACKUP_FILE" ]; then
            break
        fi
    done
    
    echo -e "\n${BLUE}Selected backup: $(basename $BACKUP_FILE)${NC}"
    echo -e "Backup size: $(du -h $BACKUP_FILE | cut -f1)"
    echo -e "Backup date: $(stat -c %y $BACKUP_FILE | cut -d' ' -f1,2)"
    echo -e "Users in backup: $(jq '.users | length' $BACKUP_FILE)"
    
    echo -e "\n${YELLOW}⚠️  Note: Existing users with same UID will be updated${NC}"
    read -p "Continue? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${RED}Restore cancelled${NC}"
        return
    fi
    
    echo -e "${YELLOW}Importing users...${NC}"
    
    firebase auth:import "$BACKUP_FILE" \
        --project "$FIREBASE_PROJECT_ID" \
        --hash-algo=SCRYPT \
        --hash-key-separator=Bw== \
        --rounds=8 \
        --mem-cost=14
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Auth users restored successfully!${NC}"
    else
        echo -e "${RED}❌ Auth restore failed${NC}"
    fi
}

# Function to create manual backup
create_manual_backup() {
    echo -e "\n${YELLOW}📦 Creating manual backup...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$BACKUP_DIR/rtdb" "$BACKUP_DIR/auth"
    
    # Backup RTDB
    echo -e "${YELLOW}Backing up Realtime Database...${NC}"
    
    read -p "Enter Firebase Database Secret (or press Enter to skip): " DB_SECRET
    
    if [ -n "$DB_SECRET" ]; then
        curl -X GET \
            "${FIREBASE_DATABASE_URL}/.json?auth=${DB_SECRET}" \
            -o "$BACKUP_DIR/rtdb/rtdb-manual-$TIMESTAMP.json"
        
        if jq empty "$BACKUP_DIR/rtdb/rtdb-manual-$TIMESTAMP.json" 2>/dev/null; then
            echo -e "${GREEN}✅ RTDB backup created: rtdb-manual-$TIMESTAMP.json${NC}"
        else
            echo -e "${RED}❌ RTDB backup failed${NC}"
        fi
    fi
    
    # Backup Auth
    echo -e "${YELLOW}Backing up Auth users...${NC}"
    
    firebase auth:export "$BACKUP_DIR/auth/auth-manual-$TIMESTAMP.json" \
        --project "$FIREBASE_PROJECT_ID"
    
    if [ -f "$BACKUP_DIR/auth/auth-manual-$TIMESTAMP.json" ]; then
        echo -e "${GREEN}✅ Auth backup created: auth-manual-$TIMESTAMP.json${NC}"
    else
        echo -e "${RED}❌ Auth backup failed${NC}"
    fi
    
    echo -e "\n${GREEN}✅ Manual backup completed!${NC}"
    echo -e "Location: $BACKUP_DIR/"
}

# Function to compare backups
compare_backups() {
    echo -e "\n${YELLOW}🔍 Comparing backups...${NC}"
    
    if [ ! -d "$BACKUP_DIR/rtdb" ]; then
        echo -e "${RED}❌ No backups to compare${NC}"
        return
    fi
    
    echo "Select first backup:"
    select FILE1 in "$BACKUP_DIR/rtdb/"*.json; do
        if [ -n "$FILE1" ]; then break; fi
    done
    
    echo "Select second backup:"
    select FILE2 in "$BACKUP_DIR/rtdb/"*.json; do
        if [ -n "$FILE2" ]; then break; fi
    done
    
    echo -e "\n${BLUE}Comparison Results:${NC}"
    echo "File 1: $(basename $FILE1) ($(du -h $FILE1 | cut -f1))"
    echo "File 2: $(basename $FILE2) ($(du -h $FILE2 | cut -f1))"
    
    echo -e "\nKeys in File 1: $(jq 'keys | length' $FILE1)"
    echo "Keys in File 2: $(jq 'keys | length' $FILE2)"
    
    # Find differences
    echo -e "\n${YELLOW}Finding differences...${NC}"
    diff <(jq -S . $FILE1) <(jq -S . $FILE2) | head -20
}

# Function to download backups from GitHub
download_github_backups() {
    echo -e "\n${YELLOW}📥 Downloading backups from GitHub...${NC}"
    
    read -p "Enter your GitHub username: " GITHUB_USER
    read -p "Enter repository name: " GITHUB_REPO
    
    echo "Cloning backups branch..."
    
    git clone -b backups "https://github.com/$GITHUB_USER/$GITHUB_REPO.git" temp-backups
    
    if [ -d "temp-backups/firebase-backups" ]; then
        cp -r temp-backups/firebase-backups/* "$BACKUP_DIR/"
        rm -rf temp-backups
        echo -e "${GREEN}✅ Backups downloaded successfully!${NC}"
    else
        echo -e "${RED}❌ No backups found in repository${NC}"
        rm -rf temp-backups
    fi
}

# Main menu
main_menu() {
    while true; do
        echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║          Main Menu                     ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo "1. 📋 List available backups"
        echo "2. 🔄 Restore Realtime Database"
        echo "3. 👥 Restore Auth Users"
        echo "4. 🔁 Full restore (RTDB + Auth)"
        echo "5. 📦 Create manual backup"
        echo "6. 🔍 Compare backups"
        echo "7. 📥 Download backups from GitHub"
        echo "8. 🚪 Exit"
        echo ""
        
        read -p "Enter your choice (1-8): " CHOICE
        
        case $CHOICE in
            1) list_backups ;;
            2) restore_rtdb ;;
            3) restore_auth ;;
            4)
                echo -e "${YELLOW}Starting full system restore...${NC}"
                restore_rtdb
                restore_auth
                echo -e "${GREEN}✅ Full system restore completed!${NC}"
                ;;
            5) create_manual_backup ;;
            6) compare_backups ;;
            7) download_github_backups ;;
            8)
                echo -e "${GREEN}Goodbye! 👋${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        echo -e "\nPress Enter to continue..."
        read
    done
}

# Start the script
authenticate_firebase
main_menu