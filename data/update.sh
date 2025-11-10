#!/bin/bash

# Ordered category names
ordered_categories=(
  "Design"
  "Code"
  "Linux - Free Software / Services"
  "Hardware"
  "Analog & Retro"
)

# Tags per category
declare -A category_tags=(
  ["Design"]="design"
  ["Code"]="code"
  ["Linux - Free Software / Services"]="linux"
  ["Hardware"]="hardware"
  ["Analog & Retro"]="retro analog"
)

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Message dictionary
declare -A MSG=(
  [missing_api_key]="ERROR: Environment variable LINKDING_API_KEY is not set."
  [set_api_key]="Hint: export LINKDING_API_KEY='your_api_key'"
  [missing_jq]="ERROR: 'jq' is not installed or not available in PATH."
  [install_jq]="Hint: Install it with: sudo apt install jq"
  [downloading]="Downloading bookmarks..."
  [done]="README.md successfully generated with sorted categories."
  [header_main]="# My Bookmarks\n\nMy personal bookmark list.\n"
  [footer]="_Last updated: %s • Total bookmarks: %s _\n"
  [exported]="Exported: %s bookmark(s)"
)

# Check for API key
if [ -z "$LINKDING_API_KEY" ]; then
  echo -e "${RED}${MSG[missing_api_key]}${NC}"
  echo -e "${YELLOW}${MSG[set_api_key]}${NC}"
  exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo -e "${RED}${MSG[missing_jq]}${NC}"
  echo -e "${YELLOW}${MSG[install_jq]}${NC}"
  exit 1
fi

# Download bookmarks
echo -e "${GREEN}${MSG[downloading]}${NC}"
curl -s -H "Authorization: Token $LINKDING_API_KEY" http://localhost:9090/api/bookmarks/ > bookmarks.json

# Input and output files
INPUT="bookmarks.json"
OUTPUT="index.md"

# Write main header
echo -e "${MSG[header_main]}" > "$OUTPUT"

# Process each category in defined order
for category in "${ordered_categories[@]}"; do
  tags="${category_tags[$category]}"
  jq_expr=$(echo "$tags" | awk '{for(i=1;i<=NF;i++) printf "any(.tag_names[]; . == \"%s\") or ", $i}')
  jq_expr="${jq_expr% or }"
  matches=$(jq -r ".results[] | select($jq_expr) | \"[\(.title)](\(.url)) - \(.description)\"" "$INPUT" | sort)
  if [ -n "$matches" ]; then
    echo "## $category" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "$matches" | sed 's/^/- /' >> "$OUTPUT"
    echo "" >> "$OUTPUT"
  fi
done

# Add summary
count=$(jq '.count' "$INPUT")
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
footer_text=---\\n$(printf "${MSG[footer]}" "$timestamp" "$count")
echo -e "$footer_text" >> "$OUTPUT"
formatted_count="${GREEN}${count}${NC}"
echo -e "$(printf "${MSG[exported]}" "$formatted_count")"
