#!/bin/env bash

#author 
#curl -s -A "Mozilla/5.0" "https://chapmanganato.to/manga-la988909" | htmlq -t 'td.table-value' | sed -n '3p 

#list search results 
#curl -s "https://manganato.com/search/story/naruto" | htmlq -t 'div.search-story-item div.item-right h3 a' | nl

#list search urls 
#curl -s "https://manganato.com/search/story/naruto" | htmlq -a href 'div.search-story-item div.item-right a'

#list chapter urls 
#curl -s -A "Mozilla/5.0" "https://chapmanganato.to/manga-la988909" | htmlq -a href 'div.panel-story-chapter-list a' 

#list search urls 
# curl -s "https://manganato.com/search/story/naruto" | htmlq -a href 'div.search-story-item a.item-img'

MANGA_ID="aa951409"  # Change this to the actual manga ID
CHAPTER_NUM="1"       # Change this for the chapter number
CHAPTER_URL="https://chapmanganato.to/manga-${MANGA_ID}/chapter-${CHAPTER_NUM}"
OUTPUT_DIR="One-Piece"
CBZ_FILENAME="${OUTPUT_DIR}/Ch.${CHAPTER_NUM}.cbz"

# Create output directory if it doesn’t exist
mkdir -p "$OUTPUT_DIR"

echo "Fetching images from: $CHAPTER_URL"

# Get image URLs from the chapter page
image_urls=$(curl -s -A "Mozilla/5.0" "$CHAPTER_URL" | htmlq -a src 'div.container-chapter-reader img')

printf "%s\n" "$image_urls"
# echo "Found $(echo "$image_urls" | wc -l) images. Downloading..."

# Download images and store in CBZ format (ZIP)
zip_file="${CBZ_FILENAME}.tmp.zip"
rm -f "$zip_file"

index=1
while IFS= read -r img_url; do
    img_name=$(printf "image_%03d.jpg" "$index")
    
    echo "Downloading: $img_name"
    
    curl -s -A "Mozilla/5.0" -e "$CHAPTER_URL" -o "$OUTPUT_DIR/$img_name" "$img_url"
    
    # Add to ZIP
    zip -jq "$zip_file" "$OUTPUT_DIR/$img_name"
    
    # Remove downloaded file after adding to ZIP
    rm -f "$OUTPUT_DIR/$img_name"

    ((index++))
done <<< "$image_urls"

# Rename ZIP to CBZ
mv "$zip_file" "$CBZ_FILENAME"

echo "Saved: $CBZ_FILENAME"

