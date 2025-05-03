#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <YouTube Video URL>"
  exit 1
fi

VIDEO_URL="$1"
VIDEO_ID=$(echo "$VIDEO_URL" | grep -oE 'v=[^&]+' | cut -d'=' -f2)

# Get title from oEmbed
TITLE=$(curl -s "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$VIDEO_ID&format=json" | jq -r '.title')

# Likes/dislikes
API_URL="https://returnyoutubedislikeapi.com/votes?videoId=$VIDEO_ID"
DATA=$(curl -s "$API_URL")
LIKES=$(echo "$DATA" | jq '.likes')
DISLIKES=$(echo "$DATA" | jq '.dislikes')
VIEWS=$(echo "$DATA" | jq '.viewCount')

# Extract raw date from meta tag
HTML=$(curl -s "$VIDEO_URL")
RAW_DATE=$(echo "$HTML" | grep -oE '<meta itemprop="datePublished" content="[^"]+"' | sed -E 's/.*content="([^"]+)".*/\1/' | head -n 1)

# Format the date if found
if [ -n "$RAW_DATE" ]; then
  # Get the date part from the RAW_DATE (before the 'T')
  DATE_ONLY=$(echo "$RAW_DATE" | cut -d'T' -f1)

  # Get the time part (after 'T')
  TIME_ONLY=$(echo "$RAW_DATE" | cut -d'T' -f2 | cut -d'-' -f1)

  # Combine date and time to form the datetime string (without the timezone)
  DATETIME="$DATE_ONLY $TIME_ONLY"

  # Convert the datetime to UTC timestamp (assumes it's UTC)
  TIMESTAMP_UTC=$(date -j -f "%Y-%m-%d %H:%M:%S" "$DATETIME" "+%s")

  # Get the local time zone offset in seconds (e.g., -10800 for UTC-3)
  LOCAL_OFFSET=$(date +%z)
  
  # Adjust the timestamp based on the local offset (in seconds)
  TIMESTAMP_LOCAL=$((TIMESTAMP_UTC + LOCAL_OFFSET))

  # Convert back to a human-readable date (adjusted to local time)
  POST_DATE=$(date -r "$TIMESTAMP_LOCAL" "+%B %d, %Y at %I:%M %p")
else
  POST_DATE="Unknown (not found)"
fi

# Like ratio
TOTAL=$((LIKES + DISLIKES))
LIKE_RATIO=$(awk -v likes="$LIKES" -v total="$TOTAL" 'BEGIN { printf "%.2f%%", (likes / total) * 100 }')

# Output
echo ""
echo "🎬  Video Title   : $TITLE"
echo "🔗  Video URL     : $VIDEO_URL"
echo "📅  Date Posted   : $POST_DATE"
echo "👍  Likes         : $LIKES"
echo "👎  Dislikes      : $DISLIKES"
echo "👁️  Views         : $VIEWS"
echo "📊  Like Ratio    : $LIKE_RATIO"
echo ""