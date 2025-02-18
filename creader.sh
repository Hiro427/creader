#!/bin/env bash

MANGA_DIR="$MANGA_DL_DIR/"
ACTIVE_SESSIONS_DIR="$HOME/.config/creader/active/"
TMP_DIR="$HOME/.config/creader/tmp/"
HEADER_DIR="$HOME/.config/creader/header.txt"
SESSION_DIR="$HOME/.config/creader/sessions/"

# TERM_WIDTH=$(tput cols)
TERM_HEIGHT=$(tput lines)

CHAPTER_LABEL="#b4befe"
PAGES_LABEL="#7f849c"
MANGA_LABEL="#f9e2af"
HEADER_COLOR="#74c7ec"
PREVIEW_KEY_COLOR="#89b4fa"
PREVIEW_VALUE_COLOR="#a6adc8"




CURRENT_INSTANCES=$(ls "$ACTIVE_SESSIONS_DIR" | wc -l) 
THIS_INSTANCE=$(("$CURRENT_INSTANCES" + 1))
DIR="$HOME/.config/creader/active/session-${THIS_INSTANCE}/"
mkdir -p "$DIR"


cleanup() {
    rm "$DIR"*.jpg 1> /dev/null 2>&1 
    rm "$DIR"*.png 1> /dev/null 2>&1
    rm "$DIR"*.gif 1> /dev/null 2>&1

    tput cnorm
}
clear_reading_sessions() {
    rm -r "$DIR"
}

trap 'clear_reading_sessions; cleanup; exit' EXIT SIGINT
 
#Formatting 
c_t() {
    local header_color="$1"
    local header="$2"

    a_r=$((16#${header_color:1:2}))
    a_g=$((16#${header_color:3:2}))
    a_b=$((16#${header_color:5:2}))

    echo -e "\e[38;2;${a_r};${a_g};${a_b}m${header}\e[0m"
}

apply_preview_color() {
    
    local key=$1 
    local value=$2

    printf "%s: %s" "$(c_t "$PREVIEW_KEY_COLOR" "$key")" \
        "$(c_t "$PREVIEW_VALUE_COLOR" "$value")" 
}

print_header() {
    c_t "$HEADER_COLOR" "$(cat "$HEADER_DIR")"
    echo " "
}

#Session Management
save_session() {

    local ses_img_index=$1
    local ses_manga_dir=$2
    local ses_ch_index=$3
    local ses_ch_title=$4
    local fmt_manga_name 

    fmt_manga_name=$(basename "$ses_manga_dir")

    # rm "$SESSION_DIR${fmt_manga_name%.*}" 2> /dev/null/
    rm -f "$SESSION_DIR/${fmt_manga_name%.*}"* 2>/dev/null


    {
        echo "Page:$ses_img_index"    
        echo "Manga:$ses_manga_dir"
        echo "Chapter:$ses_ch_index" 
        echo "Name:$ses_ch_title"
    } >> "$SESSION_DIR${fmt_manga_name}-${ses_ch_title}.txt"

    clear
    }

start_saved_session() {
    local rd_chapter_dir
    local rd_page_num 
    local rd_ch_index
    local selected_sesh 
    local sessions=()
    local fmt_ch_name

    if ls "$SESSION_DIR"*txt >/dev/null 2>&1; then 


        mapfile -t sessions < <(ls -t "$SESSION_DIR"/*.txt 2>/dev/null)


        list_sessions=()
        for file in "${sessions[@]}"; do
            list_sessions+=("$(basename "${file%.*}")")
        done

        list_sessions+=("Go Back")

        selected_sesh=$(printf "%s\n" "${list_sessions[@]}" | gum choose)

        if [[ "$selected_sesh" == "Go Back" ]]; then 
            manga_menu
        fi

        rd_page_num=$(grep "Page:" "$SESSION_DIR${selected_sesh}.txt" | cut -d':' -f2)
        rd_chapter_dir=$(grep "Manga:" "$SESSION_DIR${selected_sesh}.txt" | cut -d':' -f2)
        rd_ch_index=$(grep "Chapter:" "$SESSION_DIR${selected_sesh}.txt" | cut -d':' -f2)
        fmt_ch_name=$(get_ch "$rd_chapter_dir" "$rd_ch_index")


        

        rm "$SESSION_DIR${selected_sesh}.txt"

        display_image "$rd_ch_index" "$rd_chapter_dir" "${fmt_ch_name%.cbz}" "$rd_page_num"

    else 
        clear 
        gum confirm "No Sessions found" --affirmative "Main Menu" --negative "Exit" && manga_menu || exit 0
    fi
}


#All functions related to handling requests from MangaDex 
mdx_download_chapter() {

    local chapter_no=$1 
    local chapter_title=$2 
    local chapter_id=$3 
    local manga_title=$4 
    local download_dir

    download_dir="$MANGA_DIR${manga_title}"
    mkdir -p "$download_dir"

    format_req="https://api.mangadex.org/at-home/server/${chapter_id}"
    resp=$(curl -s "$format_req")

    base_url=$(echo "$resp" | jq -r '.baseUrl')
    hash=$(echo "$resp" | jq -r '.chapter.hash')

    mapfile -t images < <(echo "$resp" | jq -r '.chapter.data[]')

    

    cd "$download_dir/" || exit

    for image in "${images[@]}"; do 
        curl -s -o "$image" "${base_url}/data/${hash}/${image}" >/dev/null 2>&1
        sleep 0.5 #respect ratelimit 
    done

    cd "$download_dir/" || exit
    if [[ "$chapter_title" == "Title_Unavailable" ]]; then 
        find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort -V | zip -j "Ch.${chapter_no}.cbz" -@ >/dev/null 2>&1    
    else 
        find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort -V | zip -j "Ch.${chapter_no}: ${chapter_title}.cbz" -@ >/dev/null 2>&1    
    fi
    # magick *.{jpg,png} chapter.cbz
    rm "$download_dir/"*.jpg >/dev/null 2>&1
    rm "$download_dir/"*.png >/dev/null 2>&1
    rm "$download_dir/"*.gif >/dev/null 2>&1  
}



mdx_get_all_chapters() {
    local sel_manga_id="$1"
    local sel_manga_title="$2"
    local limit=10
    local offset=0

    local no_id_menu=() 
    local track_downloads=0

    echo "Fetching Chapter Data"

    while true; do
        url="https://api.mangadex.org/manga/${sel_manga_id}/feed?translatedLanguage%5B%5D=en&limit=${limit}&offset=${offset}&order%5Bchapter%5D=asc"
        
        response=$(curl -s "$url")

        if ! echo "$response" | jq '.' > /dev/null 2>&1; then
            echo "Invalid JSON response from API at offset $offset"
            break
        fi

        ids=$(echo "$response" | jq -r '[.data[] | select(.attributes.externalUrl == null)] | unique_by(.attributes.chapter) | .[] | "\(.id)~\(.attributes.title | if . == "" or . == null then "Title_Unavailable" else . end)~\(.attributes.chapter)"')


        if [ -n "$ids" ]; then
            IFS=$'\n' read -rd '' -a temp_ids <<< "$ids"
            all_chapter_ids+=("${temp_ids[@]}")
        fi


        offset=$((offset + limit))

        if [ "$(echo "$response" | jq '.data | length')" -lt "$limit" ]; then
            break
        fi
        sleep 0.5 #respect rate limit
    done
    echo "Complete"

    no_id_menu+=("00: Main-Menu")
    no_id_menu+=("00: Exit")

    for ch in "${all_chapter_ids[@]}"; do
        title_check=$(awk -F '~' '{print $2}' <<< "$ch" | tr -d '[:space:]')

        if [[ "$title_check" == "Title_Unavailable" ]]; then 
            no_id_menu+=("$(echo "$ch" | awk -F '~' '{printf "Ch.%s", $3}')") 
        else
            no_id_menu+=("$(echo "$ch" | awk -F '~' '{printf "Ch.%s: %s", $3, $2}')") 
        fi

    done

        selected_chapters=$(printf "%s\n" "${no_id_menu[@]}" | sort -V | gum filter --no-limit)

    IFS=$'\n' read -rd '' -a selected_array <<< "$selected_chapters"

    
    for sel in "${selected_array[@]}"; do
        if [[ "${#selected_array[@]}" == 1 && "${selected_array[0]}" == "00: Main-Menu" ]]; then  
            clear 
            print_header
            manga_menu
            
        elif [[ "${#selected_array[@]}" == 1 && "${selected_array[0]}" == "00: Exit" ]]; then 
            clear
            exit 0
        fi 

        clear  

        chafa --size=22x20 "${TMP_DIR}0000_cover_art.png"

        tput civis

        for ch in "${all_chapter_ids[@]}"; do


            tput cup "$((TERM_HEIGHT / 2))" 0

            echo -ne "\rDownloaded ${track_downloads}/${#selected_array[@]} Chapters"
   
            chapter_n=$(echo "$ch" | awk -F '~' '{print $3}')
            chapter_t=$(echo "$ch" | awk -F '~' '{print $2}')

            sel_num=$(echo "$sel" | cut -d':' -f1 | cut -d'.' -f2 | tr -d ' ')

            if [[ "$sel_num" == "$chapter_n" ]]; then 
                matched_id=$(echo "$ch" | awk -F '~' '{print $1}')
                mdx_download_chapter "$chapter_n" "$chapter_t" "$matched_id" "$sel_manga_title"
                # break
            fi 
        done 
        track_downloads=$((track_downloads + 1))  
        tput cup "$((TERM_HEIGHT / 2))" 0
        echo -ne "\rDownloaded ${track_downloads}/${#selected_array[@]} Chapters"
    done 
    sleep 2 
    clear
    gum confirm "Download Complete" --affirmative "Main Menu" --negative "Exit" && manga_menu || exit 0 
}



mdx_preview_screen() {

    local manga_id=$1
    local search_query=$2

    local cover_response
    local get_cover_url
    local cover_art

    local get_description
    local get_tags
    local get_title
    local get_genre
    local get_volume
    local get_pub_year

    local get_num_chapters
    local resp_chapters
    local latest_ch_id
    local latest_ch_resp

    local get_status
    local get_artist_id 
    local get_author_id 
    local request_artist
    local request_author
    

    clear

    if [[ -z "$manga_id" ]]; then 
        return
    fi 

    get_cover_url="https://api.mangadex.org/manga/${manga_id}?includes[]=cover_art"

    cover_response=$(curl -s "$get_cover_url") 
    sleep 0.2

    cover_art=$(echo "$cover_response" | jq -r '.data.relationships[] | select(.type == "cover_art") | .attributes.fileName') 

    curl -s -o "${TMP_DIR}0000_cover_art.png" "https://uploads.mangadex.org/covers/${manga_id}/${cover_art}" 
    sleep 0.2

    get_title=$(echo "$cover_response" | jq -r '.data.attributes.title.en')
    get_description=$(echo "$cover_response" | jq -r '.data.attributes.description.en')

    get_status=$(echo "$cover_response" | jq -r '.data.attributes.status') 
    if [[ "$get_status" == "completed" ]]; then 
        get_volume=$(echo "$cover_response" | jq -r '.data.attributes.lastVolume')
        get_num_chapters=$(echo "$cover_response" | jq -r '.data.attributes.lastChapter')
    else 
        get_volume="---"
        resp_chapters=$(curl -s "https://api.mangadex.org/manga/${manga_id}") 
        latest_ch_id=$(echo "$resp_chapters"| jq -r '.data.attributes.latestUploadedChapter')
        latest_ch_resp=$(curl -s "https://api.mangadex.org/chapter/${latest_ch_id}")
        sleep 0.2
        get_num_chapters=$(echo "$latest_ch_resp" | jq -r '.data.attributes.chapter')
    fi 


    get_pub_year=$(echo "$cover_response" | jq -r '.data.attributes.year')
    get_genre=$(echo "$cover_response" | jq -r '.data.attributes.publicationDemographic')
    get_tags=$(echo "$cover_response" | jq -r '.data.attributes.tags[] | .attributes.name.en')

    get_author_id=$(echo "$cover_response" | jq -r '.data.relationships[] | select(.type == "author") | .id')

    get_artist_id=$(echo "$cover_response" | jq -r '.data.relationships[] | select(.type == "artist") | .id') 

    if [[ "$get_artist_id" == "$get_author_id" ]]; then 
        request_author=$(curl -s "https://api.mangadex.org/author/${get_author_id}")
        author_name=$(echo "$request_author" | jq -r '.data.attributes.name') 
        artist_name="$author_name"

    else 
        request_artist=$(curl -s "https://api.mangadex.org/author/${get_artist_id}")
        request_author=$(curl -s "https://api.mangadex.org/author/${get_author_id}")
        artist_name=$(echo "$request_artist" | jq -r '.data.attributes.name') 
        author_name=$(echo "$request_author" | jq -r '.data.attributes.name')
    fi 


    while true; do 

        tput civis
        clear

        chafa --size=22x20 "${TMP_DIR}0000_cover_art.png"
        tput civis


        tput cup 0 25
        apply_preview_color "Title" "$get_title"

        tput cup 2 25
        apply_preview_color "Art by" "$artist_name"

        tput cup 3 25
        # echo "Art by: $author_name"
        apply_preview_color "Story by" "$author_name"

        tput cup 4 25
        apply_preview_color "Publication Year" "$get_pub_year"

        tput cup 5 25 
        apply_preview_color "Genre" "$get_genre"

        tput cup 7 25
        apply_preview_color "Chapters" "$get_num_chapters"

        tput cup 8 25
        # echo "Volumes: ${get_volume}"
        apply_preview_color "Volumes" "$get_volume"

        tput cup 9 25 
        # echo "Status: ${get_status}"
        apply_preview_color "Status" "$get_status"

        tput cup 11 25
        c_t "$PREVIEW_KEY_COLOR" "Tags"

        column_position=25
        line_position=12    

        count=0
        for tag in $get_tags; do
            if (( count % 6 == 0 )); then
                tput cup $line_position $column_position
                ((line_position++))  
            fi
            echo -n "$(c_t "$PREVIEW_VALUE_COLOR" "$tag, ")"
            ((count++))
        done

        echo

        
        tput cup 17 0

        c_t "$PREVIEW_KEY_COLOR" "Description"

        tput cup 19 0 

        c_t "$PREVIEW_VALUE_COLOR" "$get_description" | awk '/^---|^___/{exit} {print}' | fold -s -w 85

        read -rsn1 key

        if [[ "$key" == $'\e' ]]; then 
            read -rsn2 key 
        fi 

        case "$key" in
            q|SIGINT) # Quitr 
                clear
                tput cnorm
                return 
                ;;
            b) 
                clear
                print_header
                mdx_download_menu "$search_query"
                ;;
            "")  
                clear
                break
                ;;
            *)
                manga_menu
                ;;
        esac
    done


}



mdx_search_manga() {

    local search_term=$1  
    local title 

    title=$(echo "$search_term" | tr ' ' '+')


    url="https://api.mangadex.org/manga?title=${title}"
    
    response=$(curl -s "$url")

    choices=$(echo "$response" | jq -r '.data[] | "\(.attributes.title.en)~\(.id)"') 

    if [[ -z "$choices" ]]; then
        return 
    fi

    names=$(echo "$choices" | cut -d'~' -f1)

    selected_name=$(printf "Main-Menu\n%s" "$names" | gum choose) 

    if [[ "$selected_name" == "Main-Menu" ]]; then 
        return
    fi
    selected_pair=$(echo "$choices" | grep "^$selected_name~")
    selected_id=$(echo "$selected_pair" | cut -d'~' -f2)

    echo "$selected_name~$selected_id"
    
}


mdx_download_menu() {

    local s_query=$1 
    local manga_id
    local name
    local selection 

    if [[ -n "$s_query" ]]; then 
        query="$s_query"
    else 
        query=$(gum input)
    fi  


    selection=$(mdx_search_manga "$query")
    if [[ -n "$selection" ]]; then 
        name=$(echo "$selection" | cut -d'~' -f1)
        manga_id=$(echo "$selection" | cut -d'~' -f2) 

        mdx_preview_screen "$manga_id" "$query"
        mdx_get_all_chapters "$manga_id" "$name"
    else
        clear
        manga_menu
    fi

}

#Handling Manganelo/Manganato requests 
mgn_download_chapter() {

    local chapter_url=$1 
    local chapter_title
    local download_dir

    manga_title=$(curl -s -A "Mozilla/5.0" "$chapter_url" | htmlq -t 'div.panel-breadcrumb a' | sed -n '2p')
    image_urls=$(curl -s -A "Mozilla/5.0" "$chapter_url" | htmlq -a src 'div.container-chapter-reader img')
    chapter_title=$(curl -s A "Mozilla/5.0" "$chapter_url"| htmlq -t 'div.panel-breadcrumb a' | sed -n '3p' | sed 's/Chapter/Ch./g')
    download_dir="$MANGA_DIR${manga_title}"


    mkdir -p "$download_dir"



    mapfile -t images < <(printf "%s\n" "$image_urls")

    cd "$download_dir/" || exit 
    index=1
    for image in "${images[@]}"; do 
        curl -s -A "Mozilla/5.0" -e "$chapter_url" -o "image-${index}.jpg" "$image"
        sleep 0.3 #respect ratelimit 
        ((index ++))
    done

    find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort -V | zip -j "${chapter_title}.cbz" -@ >/dev/null 2>&1

    rm "$download_dir/"*.jpg >/dev/null 2>&1
    rm "$download_dir/"*.png >/dev/null 2>&1
    rm "$download_dir/"*.gif >/dev/null 2>&1


}



mgn_get_all_chapters() {
    local sel_manga_url="$1"
    local sel_manga_title="$2"
    local chapter_urls
    local chapter_titles
    local manga_page_response

    local track_downloads=0
    local selected_chapters
    local sel_ch_titles=()

    manga_page_response=$(curl -s -A "Mozilla/5.0" "$sel_manga_url")

    echo "Fetching Chapter Data"



    chapter_urls=$(echo "$manga_page_response" | htmlq -a href 'div.panel-story-chapter-list a' | sort -V)
    IFS=$'\n' read -d '' -r -a chapters_arr <<< "$chapter_urls"

    chapter_titles=$(echo "$manga_page_response" | htmlq -t 'div.panel-story-chapter-list a' | sort -V)
    IFS=$'\n' read -d '' -r -a chapters_titles_arr <<< "$chapter_titles"
  
    echo "Complete"


    selected_chapters=$(printf "%s\n" "${chapters_titles_arr[@]}" | gum filter --no-limit)

    IFS=$'\n' read -rd '' -a sel_ch_titles <<< "$selected_chapters"
    
    selected_chapter_urls=()

    # Find the index of each selected chapter in the titles array
    for selected in "${sel_ch_titles[@]}"; do
        for i in "${!chapters_titles_arr[@]}"; do
            if [[ "${chapters_titles_arr[i]}" == "$selected" ]]; then
                selected_chapter_urls+=("${chapters_arr[i]}")
                break
            fi
        done
    done 

    clear
    chafa --size=15x15 "${TMP_DIR}manga_cover.webp"
    tput civis

    for sel in "${selected_chapter_urls[@]}"; do

        tput cup "$((TERM_HEIGHT / 2))" 0

        echo -ne "\rDownloaded ${track_downloads}/${#selected_chapter_urls[@]} Chapters" 
        mgn_download_chapter "$sel"
        sleep 0.5

   
        track_downloads=$((track_downloads + 1))  
        tput cup "$((TERM_HEIGHT / 2))" 0
        echo -ne "\rDownloaded ${track_downloads}/${#selected_chapter_urls[@]} Chapters"
    done 
    sleep 2 
    clear
    gum confirm "Download Complete" --affirmative "Main Menu" --negative "Exit" && manga_menu || exit 0 
}


mgn_preview_screen() {

    local manga_url=$1
    local search_query=$2

    local manga_page_response

    local cover_response
    local get_cover_url
    local cover_art
    local chapter_urls

    local get_description
    local get_tags
    local get_title
    local get_genre
    local get_num_chapters
    local get_status
    local get_author
    

    clear

    manga_page_response=$(curl -s -A "Mozilla/5.0" "$manga_url") 

    cover_art=$(echo "$manga_page_response"| htmlq -a src '.panel-story-info img')
    curl -o "${TMP_DIR}manga_cover.webp" "$cover_art"

    get_author=$(echo "$manga_page_response" | htmlq -t 'td.table-value' | sed -n '3p' | xargs)
    get_status=$(echo "$manga_page_response" |  htmlq -t 'td.table-value' | sed -n '4p' | xargs)
    get_tags=$(echo "$manga_page_response" | htmlq -t 'td.table-value a.a-h' | tail -n +5)
    get_title=$(echo "$manga_page_response" | htmlq -t 'h1')

    chapter_urls=$(echo "$manga_page_response" | htmlq -a href 'div.panel-story-chapter-list a')
    IFS=$'\n' read -d '' -r -a chapters_array <<< "$chapter_urls"

    get_num_chapters="${#chapters_array[@]}"






    while true; do 

        tput civis
        clear

        chafa --size=22x20 "${TMP_DIR}manga_cover.webp"
        tput civis


        tput cup 0 25
        apply_preview_color "Title" "$get_title"

        tput cup 2 25
        # echo "Art by: $author_name"
        apply_preview_color "Story by" "$get_author"

        tput cup 4 25
        apply_preview_color "Chapters" "$get_num_chapters"


        tput cup 6 25 
        # echo "Status: ${get_status}"
        apply_preview_color "Status" "$get_status"

        tput cup 8 25
        c_t "$PREVIEW_KEY_COLOR" "Tags"

        column_position=25
        line_position=10    

        count=0
        for tag in $get_tags; do
            if (( count % 6 == 0 )); then
                tput cup $line_position $column_position
                ((line_position++))  
            fi
            echo -n "$(c_t "$PREVIEW_VALUE_COLOR" "$tag, ")"
            ((count++))
        done
        

        read -rsn1 key

        if [[ "$key" == $'\e' ]]; then 
            read -rsn2 key 
        fi 

        case "$key" in
            q|SIGINT) # Quitr 
                clear
                tput cnorm
                return 
                ;;
            b) 
                clear
                print_header
                mgn_download_menu "$search_query"
                ;;
            "")  
                clear
                break
                ;;
            *)
                manga_menu
                ;;
        esac
    done


}

mgn_search_manga() {

    local search_term=$1  
    local title 
    local search_response
    local title_index
    local selected_mgn_url

    title=$(echo "$search_term" | tr ' ' '_')


    url="https://manganato.com/search/story/${title}"
    
    search_response=$(curl -s "$url")

    titles=$(echo "$search_response" | htmlq -t 'div.search-story-item div.item-right h3 a') 
    title_urls=$(echo "$search_response" | htmlq -a href 'div.search-story-item a.item-img')

    IFS=$'\n' read -d '' -r -a title_array <<< "$titles"
    IFS=$'\n' read -d '' -r -a title_url_array <<< "$title_urls"

    selected_title=$(printf "Main-Menu\n%s\n" "${titles[@]}" | gum choose)
    if [[ "$selected_title" == "Main-Menu" ]]; then 
        return
    fi


    for i in "${!title_array[@]}"; do 
        if [[ "${title_array[i]}" == "$selected_title" ]]; then 
            title_index="$i"
        fi
    done

    selected_mgn_url="${title_url_array[title_index]}"

    echo "$selected_mgn_url"
    
}

mgn_download_menu() {

    local s_query=$1 
    local manga_id
    local name
    local selection 

    if [[ -n "$s_query" ]]; then 
        query="$s_query"
    else 
        query=$(gum input)
    fi  


    selection=$(mgn_search_manga "$query")
    if [[ -n "$selection" ]]; then 
        mgn_preview_screen "$selection" "$query"
        mgn_get_all_chapters "$selection"
    else
        clear
        manga_menu
    fi

}


#Reading Manga (locally)
get_ch() {

    local selected_manga=$1
    local chap_index=$2
    local selected_index

    cd "$selected_manga" || exit 

    mapfile -t chapters < <(ls | sort -V)

    if [[ -n "$chap_index" ]]; then 
      
        cd "$selected_manga" || exit 
        unzip "${chapters[chap_index]}" -d "$DIR" >/dev/null 2>&1

        echo "${chapters[chap_index]}"

    else 
        mapfile -t chapters < <(ls | sort -V)  

        selected_ch=$(printf "%s\n" "${chapters[@]}" | gum filter --height 20 --no-fuzzy --placeholder="Searching $(basename "$selected_manga")...") 


        for i in "${!chapters[@]}"; do
            if [[ "${chapters[i]}" == "$selected_ch" ]]; then
                selected_index=$i
                break
            fi
        done

        cd "$selected_manga" || exit 
        unzip "${chapters[selected_index]}" -d "$DIR" >/dev/null 2>&1

        echo "$selected_index*${chapters[selected_index]}"

    fi
}

read_single() {
    local index=$1
    local dir=$2

    local chapter_name
    local chap_info

    if [[ -n "$index" ]]; then
        chapter_name=$(get_ch "$dir" "$index")
        display_image "$index" "$dir" "$chapter_name" " "
    else 
        chap_info=$(get_ch "$dir")
        chapter_index=$(echo "$chap_info" | awk -F '*' '{print $1}')
        chapter_name=$(echo "$chap_info" | awk -F '*' '{print $2}')
        display_image "$chapter_index" "$dir" "$chapter_name" " "
    fi 

}

display_image() {

    local cur_ch_index=$1 
    local cur_manga=$2
    local ch_name=$3
    local image_ind=$4


    local width 
    local height 
    local check_term_size 
    local padding 
    local term_width 
    local term_height 
    local dimensions

    local col_pages
    local col_ch_name
    local col_manga


    cd "$DIR" || exit

    mapfile -t images < <(ls *.jpg *.png | sort -V)


    if [[ -n "$image_ind" ]]; then 
       image_index="$image_ind"
    else 
        image_index=0
    fi


    while true; do 

    clear
    dimensions=$(file "${images[image_index]}" | grep -Eo "[[:digit:]]+ *x *[[:digit:]]+" | tail -n 1)
    width=$(echo "$dimensions" | cut -d 'x' -f1 | tr -d '[:space:]')
    height=$(echo "$dimensions" | cut -d 'x' -f2 | tr -d '[:space:]')
    term_width=$(tput cols)
    term_height=$(tput lines)


    col_manga=$(c_t "$MANGA_LABEL" "$(basename "$cur_manga")")
    col_ch_name=$(c_t "$CHAPTER_LABEL" "${ch_name%.cbz}")
    col_pages=$(c_t "$PAGES_LABEL" "($((image_index + 1))/${#images[@]})")
    padding=$((term_width / 4))


    check_term_size=$((term_height - padding))
    

    if [[ "$width" -lt "$height" &&  "$check_term_size" -lt 15 ]]; then 
        tput cup 0 "$((term_width / 4 ))"  # Move cursor to center 
        chafa "${images[$image_index]}"
        tput civis 
        printf "%*s%s\n" "$padding" "" "$col_manga" 
        printf "%*s%s-%s" "$padding" "" "$col_ch_name" "$col_pages"
    else
        chafa "${images[$image_index]}"
        tput civis
        printf "%s\n%s %s" "$col_manga" "$col_ch_name" "$col_pages"
    fi

        read -rsn1 key  # Read single keypress

        if [[ "$key" == $'\e' ]]; then 
            read -rsn2 key 
        fi 

        case "$key" in
            k | '[A') 

                if [[ $image_index -eq "0" ]]; then 
                    cleanup 
                    clear 
                    cur_ch_index=$((cur_ch_index-1))
                    read_single "$cur_ch_index" "$cur_manga"
                else 
                    ((image_index = (image_index - 1 + ${#images[@]}) % ${#images[@]}))
                fi 
                                ;;
            j | '[B') 
                if [[ $image_index -eq $((${#images[@]} - 1)) ]]; then 
                    cleanup 
                    clear 
                    cur_ch_index=$((cur_ch_index+1))
                    read_single "$cur_ch_index" "$cur_manga"
                else 
                    ((image_index = (image_index + 1) % ${#images[@]}))
                fi 
                ;;
            l | '[C')
                cleanup 
                clear 
                cur_ch_index=$((cur_ch_index+1))
                read_single "$cur_ch_index" "$cur_manga"
                ;;
            h | '[D') 
                cleanup 
                clear 
                cur_ch_index=$((cur_ch_index-1))
                read_single "$cur_ch_index" "$cur_manga"
                ;;
            q|SIGINT)
                clear
                print_header
                save_session "$image_index" "$cur_manga" "$cur_ch_index" "${ch_name%.cbz}"
                cleanup
                exit
                ;;
            b)
                clear
                print_header
                save_session "$image_index" "$cur_manga" "$cur_ch_index" "${ch_name%.cbz}"
                cleanup
                read_single "" "$cur_manga"
                ;;
            s)
                save_session "$image_index" "$cur_manga" "$cur_ch_index" "${ch_name%.cbz}"
                print_header 
                gum confirm "Session was Saved" --affirmative "Continue Reading?" --negative "Exit" && return || exit 0
                ;;
            r)
                clear 
                cleanup 
                print_header
                start_saved_session
                ;;
            m)
                save_session "$image_index" "$cur_manga" "$cur_ch_index" "${chapter_name%.*}"
                cleanup
                clear 
                manga_menu
                ;;

        esac
    done
}



read_arg_file() {

    local arg_file=$1 

    local width 
    local height 
    local check_term_size 
    local padding 
    local term_width 
    local term_height 
    local image_index

    unzip "$arg_file" -d "$DIR" >/dev/null 2>&1

    cd "$DIR" || exit

    mapfile -t images < <(ls *.jpg *.png | sort -V)

    image_index=0


    while true; do 
    clear
    dimensions=$(file "${images[image_index]}" | grep -Eo "[[:digit:]]+ *x *[[:digit:]]+" | tail -n 1)
    width=$(echo "$dimensions" | cut -d 'x' -f1 | tr -d '[:space:]')
    height=$(echo "$dimensions" | cut -d 'x' -f2 | tr -d '[:space:]')
    term_width=$(tput cols)
    term_height=$(tput lines)

    col_file_name=$(ct "#b4befe" "${arg_file%.*}")
    col_pages=$(ct "#bac2de" "($((image_index + 1))/${#images[@]})")

    padding=$((term_width / 4))


    check_term_size=$((term_height - padding))


    if [[ "$width" -lt "$height" &&  "$check_term_size" -lt 15 ]]; then 
        tput cup 0 "$((term_width / 4 ))"  # Move cursor to center 
        chafa "${images[$image_index]}"
        tput civis 
        printf "%*s%s-%s" "$padding" "" "$col_file_name" "$col_pages"
    else
        chafa "${images[$image_index]}"
        tput civis
        printf "%s-%s" "$col_file_name" "$col_pages"
    fi
        # tput home

    # printf "%s - %s %s" "$col_manga" "$col_ch_name" "$col_pages"
        read -rsn1 key  # Read single keypress

        if [[ "$key" == $'\e' ]]; then 
            read -rsn2 key 
        fi 

        case "$key" in
            k | '[A') 

                ((image_index = (image_index - 1 + ${#images[@]}) % ${#images[@]}))
                ;;
            j | '[B') 
                ((image_index = (image_index + 1) % ${#images[@]}))
                ;;
            q|SIGINT) 
                clear
                cleanup
                exit
                ;;
            m)
                clear
                cleanup
                manga_menu
                ;;

        esac
    done
}

menu() {


    choose_dir=$(ls "$MANGA_DIR" | \
         sort -V |  \
         gum filter  \
         --height 20 \
         --no-fuzzy --placeholder="Searching Manga...")

    selected_dir="$MANGA_DIR$choose_dir"
    read_single "" "$selected_dir"
    }




manga_menu() {

    local main_menu_sel

    clear
    print_header


    main_menu_sel=$(echo -e "Read Manga\nDownload Manga\nReading Sessions\nExit" | gum choose)

    if [[ "$main_menu_sel" == "Read Manga" ]]; then 
        menu
    elif [[ "$main_menu_sel" == "Download Manga" ]]; then
        select_source=$(echo -e "MangaDex\nMangaNelo" | gum choose)
        case "$select_source" in 
            "MangaDex") 
                mdx_download_menu ""
                ;;
            "MangaNelo")
                mgn_download_menu ""
                ;;
        esac
    elif [[ "$main_menu_sel" == "Reading Sessions" ]]; then 
        start_saved_session
    else 
        cleanup 
        clear
        exit 0
    fi
}



if [[ "$#" -eq 1 ]]; then
    arg=$1
    if [[ "$arg" == "-cs" ]]; then 
        rm "$SESSION_DIR"*.txt
        echo "Sessions Cleared"
    else 
        extension="${arg##*.}"
        if [[ "$extension" == "cbz" ]]; then 
            read_arg_file "$arg"
        else 
            echo "invalid argument, please pass .cbz file"
        fi
    fi
elif [[ "$#" -gt 1 ]]; then 
    echo "too many arguments, only 1 is allowed"
else 
    manga_menu
fi 


