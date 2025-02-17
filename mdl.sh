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

MANGA_ID="aa951409"  
CHAPTER_NUM="1"     
CHAPTER_URL="https://chapmanganato.to/manga-${MANGA_ID}/chapter-${CHAPTER_NUM}"
OUTPUT_DIR="One-Piece"
CBZ_FILENAME="${OUTPUT_DIR}/Ch.${CHAPTER_NUM}.cbz"

mkdir -p "$OUTPUT_DIR"

echo "Fetching images from: $CHAPTER_URL"

image_urls=$(curl -s -A "Mozilla/5.0" "$CHAPTER_URL" | htmlq -a src 'div.container-chapter-reader img')

printf "%s\n" "$image_urls"

zip_file="${CBZ_FILENAME}.tmp.zip"
rm -f "$zip_file"

index=1
while IFS= read -r img_url; do
    img_name=$(printf "image_%03d.jpg" "$index")
    
    echo "Downloading: $img_name"
    
    curl -s -A "Mozilla/5.0" -e "$CHAPTER_URL" -o "$OUTPUT_DIR/$img_name" "$img_url"
    
    zip -jq "$zip_file" "$OUTPUT_DIR/$img_name"
    
    rm -f "$OUTPUT_DIR/$img_name"

    ((index++))
done <<< "$image_urls"

mv "$zip_file" "$CBZ_FILENAME"

echo "Saved: $CBZ_FILENAME"

