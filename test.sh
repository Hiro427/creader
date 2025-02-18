#!/bin/bash

# manga_page_response=$(curl -s -A "Mozilla/5.0" "https://chapmanganato.to/manga-ng952689")
#
#
# # Extract description (entire text inside div)
# description="$(echo "$manga_page_response" | htmlq -t 'h3')"
#
# echo "$description"

# fetch_chapters=$(curl -s -A "Mozilla/5.0" "https://chapmanganato.to/manga-la988909" | htmlq -a href 'li.row-content-chapter a' )

# echo "$fetch_chapters"
manga_page_response=$(curl -s -A "Mozilla/5.0" "https://chapmanganato.to/manga-ng952689/chapter-1")

# Extract all chapter URLs
chapter_urls=$(echo "$manga_page_response" | htmlq -t 'div.panel-breadcrumb a' | sed -n '3p')

echo "$chapter_urls"

# IFS=$'\n' read -d '' -r -a chapters_array <<< "$chapter_urls"


# num_chapters="${#chapters_array[@]}"



# # Fetch the manga page content
# # Print extracted URLs
# echo "=== CHAPTER URLs ==="
# echo "$chapter_urls"
# echo "===================="

