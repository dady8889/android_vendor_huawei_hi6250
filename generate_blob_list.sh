#!/bin/bash
# Copyright (C) 2017 dady8889@github

# Define output file
OUTPUT=device-proprietary-files.txt

# Clear output file
#[ -e $OUTPUT ] && rm $OUTPUT
(cat << EOF) > $OUTPUT
# This file was automatically generated by generate_blob_list.sh

EOF

# Count all files
COUNT=$(find . -mindepth 2 -not -type d -and -not -path '*/\.*' -and -not -name "*.apk" -and -not -name "*.mk" -and -not -name "*.bp" | wc -l)

echo "!REMEMBER apk, bp, mk, hidden files, hidden directories or files in current directory are NOT included!"
echo "Generating proprietary files list..."

# Iterate all subdirectories except current directory, [apk, bp, mk] files, hidden files
PROGRESS=0
find . -mindepth 2 -not -type d -and -not -path '*/\.*' -and -not -name "*.apk" -and -not -name "*.mk" -and -not -name "*.bp" -print0 | while IFS= read -r -d '' file
do
    # Get file path
    BLOB=$(echo "$file" | cut -c 3-)

    # Append blob to output
    echo $BLOB >> $OUTPUT

    # Show progress
    PROGRESS=$((PROGRESS+1))
    echo -ne "\033[K[$PROGRESS/$COUNT] $BLOB\r"
done

echo "[$COUNT/$COUNT] $OUTPUT is now full of blobs!"
