#!/bin/bash

# PSP Photo Organizer - Complete Solution
# Combines image conversion, organization, and timestamp setting for optimal PSP viewing
#
# Features:
# - Convert various image formats to JPG
# - Organize files into comic format (001.jpg, 002.jpg, etc.)
# - Set timestamps with 1-minute increments for PSP compatibility
# - Batch processing for multiple directories
# - Preserves original files (works on copies)

set -e  # Exit on any error

# Function to show usage
show_usage() {
    echo "PSP Photo Organizer - Complete Solution"
    echo "======================================"
    echo ""
    echo "Usage: $0 [OPTIONS] SOURCE_DIR [TARGET_DIR]"
    echo ""
    echo "Complete photo organization for PSP including conversion, organization, and timestamp setting."
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Verbose output"
    echo "  -c, --comic-mode        Enable comic book mode (sequential numbering)"
    echo "  -b, --batch             Process subdirectories as separate comics"
    echo "  -p, --preserve-dates    Preserve original file dates during organization"
    echo "  -t, --timestamps        Set 1-minute increment timestamps for PSP compatibility"
    echo "  -s, --start-time TIME   Start time for timestamps (YYYY-MM-DD HH:MM, defaults to yesterday midnight)"
    echo "  -q, --quality PERCENT   JPG quality for conversion (default: 80)"
    echo "  --no-convert            Skip image conversion step"
    echo ""
    echo "SOURCE_DIR: Directory containing images to process"
    echo "TARGET_DIR: Optional destination directory (defaults to 'PSP_Organized' in SOURCE_DIR)"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/images                                    # Full pipeline with defaults"
    echo "  $0 -c /path/to/comic/pages                           # Comic mode only"
    echo "  $0 -c -t /path/to/comic/pages                        # Comic mode + timestamps"
    echo "  $0 -c -b -t /comics/library                          # Batch processing with timestamps"
    echo "  $0 -c --no-convert /already/jpg/folder               # Skip conversion, organize only"
    echo "  $0 -v -q 85 -s \"2025-01-01 12:00\" /images          # Custom quality and start time"
}

# Default settings
VERBOSE=false
COMIC_MODE=false
BATCH_MODE=false
PRESERVE_DATES=false
SET_TIMESTAMPS=false
CONVERT_IMAGES=true
START_TIME=""
QUALITY=80
SOURCE_DIR=""
TARGET_DIR=""
TEMP_DIR=""

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
        -c|--comic-mode)
            COMIC_MODE=true
            shift
            ;;
        -b|--batch)
            BATCH_MODE=true
            shift
            ;;
        -p|--preserve-dates)
            PRESERVE_DATES=true
            shift
            ;;
        -t|--timestamps)
            SET_TIMESTAMPS=true
            shift
            ;;
        -s|--start-time)
            START_TIME="$2"
            shift
            shift
            ;;
        -q|--quality)
            QUALITY="$2"
            shift
            shift
            ;;
        --no-convert)
            CONVERT_IMAGES=false
            shift
            ;;
        -*)
            echo "Error: Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$SOURCE_DIR" ]]; then
                SOURCE_DIR="$1"
            elif [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="$1"
            else
                echo "Error: Too many arguments"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Function to log messages
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "$@"
    fi
}

# Function to log regular messages (always shown)
log_info() {
    echo "$@"
}

# Function to validate directory
validate_directory() {
    local dir="$1"
    local dir_name="$2"

    if [[ -z "$dir" ]]; then
        echo "Error: $dir_name is required"
        show_usage
        exit 1
    fi

    if [[ ! -d "$dir" ]]; then
        echo "Error: $dir_name '$dir' does not exist"
        exit 1
    fi
}

# Function to convert and compress images while preserving order
convert_images_with_order() {
    local source="$1"
    local target="$2"
    local original_files=("${@:3}")

    log_info "=== Image Conversion & Compression ==="
    log_info "Converting images while preserving original order..."

    # Change to source directory
    cd "$source" || exit 1

    # Create output directory
    mkdir -p "$target"

    # Convert files in the order they appear in original_files array
    for original_file in "${original_files[@]}"; do
        if [[ -f "$original_file" ]]; then
            local extension="${original_file##*.}"
            local base="${original_file%.*}"

            # Convert non-JPG files to JPG
            if [[ "$extension" =~ ^(png|PNG|webp|WEBP|gif|GIF|bmp|BMP)$ ]]; then
                log "Converting: $original_file → $base.jpg"
                if command -v magick >/dev/null 2>&1; then
                    magick "$original_file" "$base.jpg"
                else
                    echo "Warning: ImageMagick not found. Install with: brew install imagemagick"
                    echo "Skipping conversion for $original_file"
                    continue
                fi
            fi
        fi
    done

    # Copy all JPGs to target in original order (with compression if available)
    log_info "Copying JPG files to $target in original order..."

    local counter=0
    for original_file in "${original_files[@]}"; do
        if [[ -f "$original_file" ]]; then
            local extension="${original_file##*.}"

            # Only process JPG files (either original or converted)
            if [[ "$extension" =~ ^(jpg|JPG|jpeg|JPEG)$ ]]; then
                local base=$(basename "$original_file")

                if command -v mogrify >/dev/null 2>&1; then
                    # Use mogrify for compression optimization
                    cp "$original_file" "$target/"
                    mogrify -quality "$QUALITY" -strip -sampling-factor 4:2:0 "$target/$base"
                else
                    echo "Warning: ImageMagick not found. Install with: brew install imagemagick"
                    echo "Copying without compression optimization..."
                    cp "$original_file" "$target/"
                fi
                ((counter++))
            fi
        fi
    done

    log_info "Converted and copied $counter files in original order"
    cd - >/dev/null || exit 1
}

# Function to organize files while preserving order
organize_files_with_order() {
    local source="$1"
    local target="$2"
    local original_files=("${@:3}")

    log_info "=== File Organization ==="
    log "Organizing ${#original_files[@]} files in original order..."

    # Create target directory
    mkdir -p "$target"

    # Organize files in the order they appear in original_files array
    local counter=1
    for original_file in "${original_files[@]}"; do
        if [[ -f "$source/$original_file" ]]; then
            local extension="${original_file##*.}"

            # Only process JPG files
            if [[ "$extension" =~ ^(jpg|JPG|jpeg|JPEG)$ ]]; then
                local padded_counter=$(printf "%03d" $counter)

                if [[ "$COMIC_MODE" == true ]]; then
                    local new_filename="${padded_counter}.jpg"
                else
                    # For PSP photo mode, keep original date-based organization
                    # but rename to avoid conflicts
                    local new_filename="IMG_${padded_counter}.jpg"
                fi

                local target_file="$target/$new_filename"

                log "Copying: $original_file -> $new_filename"

                # Copy file and preserve dates if requested
                if [[ "$PRESERVE_DATES" == true ]]; then
                    cp -p "$source/$original_file" "$target_file"
                else
                    cp "$source/$original_file" "$target_file"
                fi

                ((counter++))
            fi
        fi
    done

    log_info "Successfully organized $((counter-1)) files to $target"
}

# Function to convert and compress images
convert_images() {
    local source="$1"
    local target="$2"

    log_info "=== Image Conversion & Compression ==="
    log_info "Checking for image files in: $source"

    # Change to source directory
    cd "$source" || exit 1

    # Find all supported image files in original order
    shopt -s nullglob
    local files=(*.jpg *.jpeg *.png *.webp *.gif *.bmp *.JPG *.JPEG *.PNG *.WEBP *.GIF *.BMP)

    if [ ${#files[@]} -eq 0 ]; then
        log_info "No supported image files found."
        return 0
    fi

    log_info "Found ${#files[@]} image(s). Converting to JPG if needed..."

    # Create output directory
    mkdir -p "$target"

    # Convert non-JPG files to JPG first, preserving order
    for f in *.png *.webp *.gif *.bmp *.PNG *.WEBP *.GIF *.BMP; do
        [ -e "$f" ] || continue
        base="${f%.*}"
        log "Converting: $f → $base.jpg"
        if command -v magick >/dev/null 2>&1; then
            magick "$f" "$base.jpg"
        else
            echo "Warning: ImageMagick not found. Install with: brew install imagemagick"
            echo "Skipping conversion for $f"
        fi
    done

    # Copy all JPGs to target in the correct order (preserving original file order)
    log_info "Copying JPG files to $target in original order..."

    # Get JPG files in original directory order (not sorted by time)
    local jpg_files=()
    for f in "${files[@]}"/*.jpg "${files[@]}"/*.JPG "${files[@]}"/*.jpeg "${files[@]}"/*.JPEG; do
        [ -e "$f" ] || continue
        jpg_files+=("$f")
    done 2>/dev/null

    if [ ${#jpg_files[@]} -eq 0 ]; then
        log_info "No JPG files to copy."
        cd - >/dev/null || exit 1
        return 0
    fi

    # Copy files in original order
    for f in "${jpg_files[@]}"; do
        if [[ -f "$f" ]]; then
            if command -v mogrify >/dev/null 2>&1; then
                # Use mogrify for compression optimization
                cp "$f" "$target/"
                base=$(basename "$f")
                mogrify -quality "$QUALITY" -strip -sampling-factor 4:2:0 "$target/$base"
            else
                echo "Warning: ImageMagick not found. Install with: brew install imagemagick"
                echo "Copying without compression optimization..."
                cp "$f" "$target/"
            fi
        fi
    done

    log_info "Image conversion and compression complete!"
    cd - >/dev/null || exit 1
}

# Function to organize files
organize_files() {
    local source="$1"
    local target="$2"

    log_info "=== File Organization ==="
    log "Scanning directory: $source"
    log "Target directory: $target"

    # Find all .jpg files in directory order (not time-sorted)
    local jpg_files=()
    for f in "$source"/*.jpg "$source"/*.JPG; do
        [ -f "$f" ] && jpg_files+=("$f")
    done 2>/dev/null

    if [ ${#jpg_files[@]} -eq 0 ]; then
        echo "No .jpg files found in $source"
        return 0
    fi

    log "Found ${#jpg_files[@]} .jpg files"

    # Create organized files
    local counter=1
    local total_files=${#jpg_files[@]}

    log_info "Organizing $total_files files..."

    for file in "${jpg_files[@]}"; do
        if [[ -f "$file" ]]; then
            local extension="${file##*.}"
            local padded_counter=$(printf "%03d" $counter)

            if [[ "$COMIC_MODE" == true ]]; then
                local new_filename="${padded_counter}.jpg"
            else
                # For PSP photo mode, keep original date-based organization
                # but rename to avoid conflicts
                local new_filename="IMG_${padded_counter}.jpg"
            fi

            local target_file="$target/$new_filename"

            log "Copying: $(basename "$file") -> $new_filename"

            # Copy file and preserve dates if requested
            if [[ "$PRESERVE_DATES" == true ]]; then
                cp -p "$file" "$target_file"
            else
                cp "$file" "$target_file"
            fi

            ((counter++))
        fi
    done

    log_info "Successfully organized $((counter-1)) files to $target"
}

# Function to set timestamps with 1-minute increments
set_timestamps() {
    local directory="$1"

    log_info "=== Setting PSP Timestamps ==="
    log "Directory: $directory"

    # Set start time
    if [[ -z "$START_TIME" ]]; then
        # Use yesterday at midnight of current date as starting point
        START_TIME=$(date -v-1d +"%Y-%m-%d 00:00")
    fi

    log_info "Start time: $START_TIME"

    # Validate start time format
    if ! date -j -f "%Y-%m-%d %H:%M" "$START_TIME" &>/dev/null; then
        echo "Error: Invalid start time format. Use YYYY-MM-DD HH:MM"
        exit 1
    fi

    # Find all .jpg files and sort them
    local jpg_files=$(find "$directory" -maxdepth 1 -name "*.jpg" -o -name "*.JPG" | sort)

    if [[ -z "$jpg_files" ]]; then
        echo "No .jpg files found in $directory"
        return 0
    fi

    local total_files=$(echo "$jpg_files" | wc -l)
    log_info "Found $total_files .jpg files"

    # Parse start time
    local start_year=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%Y")
    local start_month=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-m")
    local start_day=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-d")
    local start_hour=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-H")
    local start_minute=$(date -j -f "%Y-%m-%d %H:%M" "$START_TIME" +"%-M")

    log_info "Setting timestamps with 1-minute increments..."

    local counter=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Calculate timestamp for this file (start + counter minutes)
            local target_minute=$((start_minute + counter))

            # Handle minute overflow (if minutes >= 60, increment hour)
            local extra_hours=0
            if [[ $target_minute -ge 60 ]]; then
                extra_hours=$((target_minute / 60))
                target_minute=$((target_minute % 60))
            fi

            local target_hour=$((start_hour + extra_hours))

            # Handle hour overflow (if hours >= 24, increment day)
            if [[ $target_hour -ge 24 ]]; then
                local extra_days=$((target_hour / 24))
                target_hour=$((target_hour % 24))
                # For simplicity, we'll assume we won't exceed 24 hours
            fi

            if [[ $extra_hours -eq 0 ]]; then
                target_hour=$start_hour
            fi

            # Format the timestamp for display
            local timestamp=$(printf "%04d-%d-%d %d:%02d" $start_year $start_month $start_day $target_hour $target_minute)

            # Format the timestamp for touch command (no dashes)
            local touch_timestamp=$(printf "%04d%02d%02d%02d%02d" $start_year $start_month $start_day $target_hour $target_minute)

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

    log_info "Successfully set timestamps for $counter files"
    log_info "Timestamp progression: Start: $START_TIME -> End: $timestamp"
}

# Function to process batch mode (multiple subdirectories)
process_batch() {
    local source="$1"
    local target="$2"

    log_info "=== Batch Processing Mode ==="
    log_info "Processing subdirectories as separate comics..."

    # Find all subdirectories (excluding hidden ones)
    local subdirs=$(find "$source" -type d -not -path "$source" -not -path "*/.*")

    if [[ -z "$subdirs" ]]; then
        echo "No subdirectories found in $source"
        return 0
    fi

    local total_dirs=$(echo "$subdirs" | wc -l)
    log_info "Found $total_dirs subdirectories to process"

    local processed_count=0

    while IFS= read -r subdir; do
        if [[ -d "$subdir" ]]; then
            local dir_name=$(basename "$subdir")
            local target_subdir="$target/$dir_name"

            log "Processing subdirectory: $dir_name"

            # Get original file order for this subdirectory
            cd "$subdir" || continue
            shopt -s nullglob
            local subdir_files=(*.jpg *.jpeg *.png *.webp *.gif *.bmp *.JPG *.JPEG *.PNG *.WEBP *.GIF *.BMP)
            cd - >/dev/null || continue

            # Check if this subdirectory has image files
            if [ ${#subdir_files[@]} -gt 0 ]; then
                mkdir -p "$target_subdir"

                # Create a temporary working directory for this subdirectory
                local temp_working_dir="$target_subdir"
                if [[ "$CONVERT_IMAGES" == true ]]; then
                    temp_working_dir="$target_subdir/temp_convert"
                    mkdir -p "$temp_working_dir"
                    convert_images_with_order "$subdir" "$temp_working_dir" "${subdir_files[@]}"
                else
                    # If not converting, copy files to temp directory for processing
                    mkdir -p "$temp_working_dir"
                    # Copy files in original order, not sorted by time
                    local counter=0
                    for original_file in "${subdir_files[@]}"; do
                        if [[ -f "$subdir/$original_file" ]]; then
                            local extension="${original_file##*.}"
                            if [[ "$extension" =~ ^(jpg|JPG|jpeg|JPEG)$ ]]; then
                                cp "$subdir/$original_file" "$temp_working_dir/"
                                ((counter++))
                            fi
                        fi
                    done
                    log "Copied $counter files in original order"
                fi

                # Organize files
                organize_files_with_order "$temp_working_dir" "$target_subdir" "${subdir_files[@]}"

                # Clean up temp directory if it exists
                if [[ "$temp_working_dir" != "$target_subdir" ]]; then
                    rm -rf "$temp_working_dir"
                fi

                # Set timestamps if requested
                if [[ "$SET_TIMESTAMPS" == true ]]; then
                    set_timestamps "$target_subdir"
                fi

                ((processed_count++))
            else
                log "No image files in $dir_name, skipping"
            fi
        fi
    done <<< "$subdirs"

    log_info "Batch processing complete: $processed_count directories processed"
}

# Main execution
log_info "PSP Photo Organizer - Complete Solution"
log_info "======================================"

# Validate source directory
validate_directory "$SOURCE_DIR" "Source directory"

# Set default target directory if not provided
if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="$SOURCE_DIR/PSP_Organized"
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Show configuration
log_info ""
log_info "Configuration:"
log_info "  Source: $SOURCE_DIR"
log_info "  Target: $TARGET_DIR"
log_info "  Comic Mode: $COMIC_MODE"
log_info "  Batch Mode: $BATCH_MODE"
log_info "  Convert Images: $CONVERT_IMAGES"
log_info "  Set Timestamps: $SET_TIMESTAMPS"
log_info "  Quality: $QUALITY%"
if [[ -n "$START_TIME" ]]; then
    log_info "  Start Time: $START_TIME"
fi
log_info ""

# Check for ImageMagick if conversion is enabled
if [[ "$CONVERT_IMAGES" == true ]] && ! command -v magick >/dev/null 2>&1; then
    log_info "Warning: ImageMagick not found. Install with: brew install imagemagick"
    log_info "Continuing with file operations only..."
    log_info ""
fi

# Get original file order (this preserves the source directory order)
log_info "Getting original file order..."
cd "$SOURCE_DIR" || exit 1
shopt -s nullglob
ORIGINAL_FILES=(*.jpg *.jpeg *.png *.webp *.gif *.bmp *.JPG *.JPEG *.PNG *.WEBP *.GIF *.BMP)
cd - >/dev/null || exit 1

if [ ${#ORIGINAL_FILES[@]} -eq 0 ]; then
    log_info "No supported image files found in source directory."
    exit 0
fi

log_info "Found ${#ORIGINAL_FILES[@]} files in original order"

# Process files
if [[ "$BATCH_MODE" == true ]]; then
    process_batch "$SOURCE_DIR" "$TARGET_DIR"
else
    # Create a temporary working directory if converting images
    if [[ "$CONVERT_IMAGES" == true ]]; then
        TEMP_DIR="$TARGET_DIR/temp_convert"
        mkdir -p "$TEMP_DIR"
        convert_images_with_order "$SOURCE_DIR" "$TEMP_DIR" "${ORIGINAL_FILES[@]}"
        organize_files_with_order "$TEMP_DIR" "$TARGET_DIR" "${ORIGINAL_FILES[@]}"
        # Clean up temp directory
        rm -rf "$TEMP_DIR"
    else
        # If not converting, organize directly from source using original order
        organize_files_with_order "$SOURCE_DIR" "$TARGET_DIR" "${ORIGINAL_FILES[@]}"
    fi

    # Set timestamps if requested
    if [[ "$SET_TIMESTAMPS" == true ]]; then
        set_timestamps "$TARGET_DIR"
    fi
fi

# Final summary
log_info ""
log_info "=== Processing Complete ==="
log_info "Organized files saved to: $TARGET_DIR"
log_info ""

# PSP usage instructions
log_info "For PSP use:"
log_info "1. Copy the '$TARGET_DIR' folder to your PSP's memory stick"
log_info "2. Look for it in the 'Photo' section of your PSP"

if [[ "$BATCH_MODE" == true ]]; then
    log_info "3. Each subdirectory will appear as a separate comic/photo album"
    log_info "4. Files within each folder are sorted by creation date"
else
    log_info "3. Files should appear in the correct order based on creation dates"
fi

if [[ "$COMIC_MODE" == true ]]; then
    log_info ""
    log_info "Comic Book Notes:"
    log_info "- Files are renamed as 001.jpg, 002.jpg, etc. for sequential reading"
    log_info "- PSP will display them in numerical order"
    log_info "- Perfect for reading comic books page by page"
fi

if [[ "$SET_TIMESTAMPS" == true ]]; then
    log_info ""
    log_info "Timestamp Notes:"
    log_info "- Files have 1-minute timestamp increments for PSP compatibility"
    log_info "- PSP can now properly distinguish and sort all files"
    log_info "- Files will appear in correct chronological order on PSP"
fi

log_info ""
log_info "Done! Your files are now optimized for PSP viewing."
