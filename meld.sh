#!/bin/sh

# Initialize our own variables:
output="output.jpeg"
verbose=0
top=""
bottom=""
list=""
work_dir=cache/work
oracle_text=

show_help() {
    echo "Stuff"
    exit
}

title_case() {
    echo "$1" | sed 's/.*/\L&/; s/[a-z]*/\u&/g'     
}

simplify_text() {
    echo "$1" | sed "s/[^[:alnum:]-]//g"  | tr '[:upper:]' '[:lower:]'
}

oracle_text_size() {
    local text_length=${#1}
    local line_count=$(echo $1 | wc -l)

    if [ "$line_count" -gt 8 ]
    then
        echo 16
    elif [ "$line_count" -gt 6 ]
    then
        echo 18
    else
        if [ "$text_length" -gt 600 ]
        then
            echo 15
        elif [ "$text_length" -gt 500 ]
        then
            echo 17
        elif [ "$text_length" -gt 400 ]
        then
            echo 19
        elif [ "$text_length" -gt 300 ]
        then
            echo 22
        elif [ "$text_length" -gt 200 ]
        then
            echo 25
        else
            echo 28
        fi
    fi
}

card_face_supplier() {
    local file="cache/$1.jpeg.txt"
    
    if jq  -e ".data[0].$2" "$file" >/dev/null
    then
       jq  ".data[0].$2" "$file" | tr -d '"'
    else
        local front_face="$(jq ".data[0].card_faces[0].name" "$file")"
        if [ "$(simplify_text "$1")" = "$(simplify_text "$front_face")" ]
        then
            jq  ".data[0].card_faces[0].$2" "$file" | tr -d '"'
        else
            jq  ".data[0].card_faces[1].$2" "$file" | tr -d '"'
        fi
    fi
}

download_card() {
    echo "Downloading card details and high res image for $1..."


    curl -L -G  --header "Accept=*/*" \
    --data-urlencode "q=!\"$1\" -set:lea order:release direction:ascending game:paper prefer:oldest" \
    https://api.scryfall.com/cards/search \
    -o "$2.txt"
    
    if jq  -e '.data[0].image_uris.png' "$2.txt" > /dev/null
    then
        curl -L -G  --header "Accept=*/*" \
        $(jq  '.data[0].image_uris.png' "$2.txt" | tr -d '"')  \
        -o "$2"
    else
        local front_face="$(jq '.data[0].card_faces[0].name' "$2.txt")"
        if [ "$(simplify_text "$1")" = "$(simplify_text "$front_face")" ]
        then
            curl -L -G  --header "Accept=*/*" \
            $(jq  '.data[0].card_faces[0].image_uris.png' "$2.txt" | tr -d '"')  \
            -o "$2"
        else
            curl -L -G  --header "Accept=*/*" \
            $(jq  '.data[0].card_faces[1].image_uris.png' "$2.txt" | tr -d '"')  \
            -o "$2"

        fi
    fi
}


meld_card(){
    echo "Generating Proxy for $top $bottom..."
    mkdir -p "$work_dir"
    top_file="cache/$top.jpeg"
    bottom_file="cache/$bottom.jpeg"
    
    if [ ! -f "$top_file" ]
    then
        download_card "$top" "$top_file"
    fi
    if [ -z "$bottom" ]
    then
        convert "$top_file" "$(echo "output/$top.png" | tr " " _)"
    else
        if [ ! -f "$bottom_file" ]
        then
            download_card "$bottom" "$bottom_file"  
        fi
        output_file="output/$(echo "$top#$bottom.png" | tr " " _)"
        artists="$(card_face_supplier "$top" 'artist') / $(card_face_supplier "$bottom" 'artist')"
        convert "$top_file" DividingLine.png -alpha off -compose CopyOpacity -composite $work_dir/tmp.png
        convert "$bottom_file" DividingLine.png -alpha off -rotate 180 -compose CopyOpacity -composite $work_dir/tmp2.png
        convert $work_dir/tmp.png $work_dir/tmp2.png -alpha set -composite $work_dir/tmp.png
        convert $work_dir/tmp.png -pointsize 16 -draw "gravity south fill white text 0,10 '$artists'" "$output_file"

        if [ ! -z "$oracle_text" ]
        then
            echo " - Appending oracle text..."

            top_oracle_text="$(card_face_supplier "$top" 'oracle_text')"
            bottom_oracle_text="$(card_face_supplier "$bottom" 'oracle_text')"
            convert \( -background '#FFF6'  -font JaceBeleren-Bold -fill black -pointsize $(oracle_text_size "$top_oracle_text") -size 550x180 \
                    -bordercolor '#FFFA'  -border 10 \
                    -mattecolor '#FFF9'  -frame 5x5+0+2 \
                    caption:"$top_oracle_text" \) \
                    "$output_file" +swap -gravity north -geometry +0+130 -composite "$output_file"
                
            convert \( -background '#FFF6' -font JaceBeleren-Bold -fill black -pointsize $(oracle_text_size "$bottom_oracle_text") -size 550x180 \
                    -bordercolor '#FFFA'  -border 10 \
                    -mattecolor '#FFF9'  -frame 5x5+0+2 \
                    caption:"$bottom_oracle_text" -rotate 180 \) \
                    "$output_file" +swap -gravity south -geometry +0+130 -composite "$output_file"
        fi
        
        #convert "$output_file" CornerMask.png -alpha off -compose CopyOpacity -composite "$output_file"
        
        rm -rf "$work_dir/*"
    fi
}

# A POSIX variable
# Reset in case getopts has been used previously in the shell.
OPTIND=1

while getopts "h?f:t:b:o" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    o)
        oracle_text="true"
        ;;
    t)  
        top="$(title_case "$OPTARG")"
        ;;
    b)  
        bottom="$(title_case "$OPTARG")"
        ;;
    f)  list="$OPTARG"
        ;;
    esac
done
shift $((OPTIND-1))

mkdir -p cache
rm -rf output/*
mkdir -p output

if [ -z "$list" ]
then
    meld_card
else
    while read line
    do 
        top="$(echo $line | cut -f 1 -d =)"
        bottom="$(echo $line | cut -f 2 -d =)"
        top="$(title_case "$top")"
        bottom="$(title_case "$bottom")"
        meld_card
    done < $list
fi

echo "Generating PDF..."

#https://www.slightlymagic.net/forum/viewtopic.php?f=46&t=1241
#olze » 04 Jun 2009, 16:38 
montage -density 297 -tile 3x3 -geometry +2+2 output/*.png output/montage.png
convert output/montag*.png  output/montage.pdf
