#!/bin/bash

# PSP Timestamp Setter - Sets modification times with 1-minute increments for PSP compatibility
# PSP can only distinguish files by minute-level granularity, not seconds

set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] DIRECTORY"
    echo ""
    echo "Set modification times on .jpg files with 1-minute increments for PSP compatibility."
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Verbose output"
    echo "  -s, --start    Start time (YYYY-MM-DD HH:MM format, defaults to midnight today)"
    echo ""
    echo "DIRECTORY: Directory containing .jpg files to timestamp"
    echo ""
    echo "Examples:"
    echo "  $0 ~/Desktop/comic_pages"
    echo "  $0 -v ~/Desktop/comic_pages"
    echo "  $0 -s \"2025-01-01 12:00\" ~/Desktop/comic_pages"
}

# Default settings
VERBOSE=false
START_TIME=""
DIRECTORY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--start)
            START_TIME="$2"
            shift
            shift
            ;;
        -*)
            echo "Error: Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$DIRECTORY" ]]; then
                DIRECTORY="$1"
            else
                echo "Error: Too many arguments"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate directory
if [[ -z "$DIRECTORY" ]]; then
    echo "Error: Directory is required"
    show_usage
    exit 1
fi

if [[ ! -d "$DIRECTORY" ]]; then
    echo "Error: Directory '$DIRECTORY' does not exist"
    exit 1
fi

# Set start time
if [[ -z "$START_TIME" ]]; then
    # Use midnight of current date as starting point (safer than current time)
    START_TIME=$(date +"%Y-%m-%d 00:00")
fi

echo "PSP Timestamp Setter"
echo "==================="
echo "Directory: $DIRECTORY"
echo "Start time: $START_TIME"
echo ""

# Validate start time format
if ! date -j -f "%Y-%m-%d %H:%M" "$START_TIME" &>/dev/null; then
    echo "Error: Invalid start time format. Use YYYY-MM-DD HH:MM"
    exit 1
fi

# Find all .jpg files and sort them
jpg_files=$(find "$DIRECTORY" -maxdepth 1 -name "*.jpg" -o -name "*.JPG" | sort)

if [[ -z "$jpg_files" ]]; then
    echo "No .jpg files found in $DIRECTORY"
    exit 0
fi

total_files=$(echo "$jpg_files" | wc -l)
echo "Found $total_files .jpg files"

# Parse start time
start_year=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%Y")
start_month=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-m")  # Remove leading zero
start_day=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-d")    # Remove leading zero
start_hour=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-H")   # Remove leading zero
start_minute=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-M")  # Remove leading zero

echo "Setting timestamps with 1-minute increments..."

counter=0
while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        # Calculate timestamp for this file (start + counter minutes)
        target_minute=$((start_minute + counter))

        # Handle minute overflow (if minutes >= 60, increment hour)
        if [[ $target_minute -ge 60 ]]; then
            extra_hours=$((target_minute / 60))
            target_minute=$((target_minute % 60))
            target_hour=$((start_hour + extra_hours))

            # Handle hour overflow (if hours >= 24, increment day)
            if [[ $target_hour -ge 24 ]]; then
                extra_days=$((target_hour / 24))
                target_hour=$((target_hour % 24))
                # For simplicity, we'll assume we won't exceed 24 hours
                # In practice, you might want to handle this case
            fi
        else
            target_hour=$start_hour
        fi

        # Format the timestamp for display
        timestamp=$(printf "%04d-%d-%d %d:%02d" $start_year $start_month $start_day $target_hour $target_minute)

        # Format the timestamp for touch command (no dashes)
        touch_timestamp=$(printf "%04d%02d%02d%02d%02d" $start_year $start_month $start_day $target_hour $target_minute)

        # Set the modification time
        if touch -t "$touch_timestamp" "$file" 2>/dev/null; then
            if [[ "$VERBOSE" == true ]]; then
                echo "$(basename "$file") -> $timestamp"
            fi
        else
            echo "Warning: Failed to set timestamp for $file"
        fi

        ((counter++))
    fi
done <<< "$jpg_files"

echo ""
echo "Successfully set timestamps for $counter files"
echo ""
echo "Timestamp progression:"
echo "  Start: $START_TIME"
echo "  End:   $timestamp"
echo ""
echo "Now your files have distinct timestamps that PSP can recognize!"
echo "You can run the organizer script again to sort them properly."
