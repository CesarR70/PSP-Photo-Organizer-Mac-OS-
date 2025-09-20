#!/bin/bash

# PSP Photo Organizer Script for macOS
# Organizes .jpg files by creation date for proper PSP viewing order

set -e  # Exit on any error

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] SOURCE_DIR [TARGET_DIR]"
    echo ""
    echo "Organize .jpg files for PSP viewing by creation date."
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --comic-mode    Enable comic book mode (sequential numbering)"
    echo "  -p, --preserve-dates Preserve original file dates"
    echo "  -v, --verbose       Verbose output"
    echo "  -b, --batch         Process subdirectories as separate comics"
    echo ""
    echo "SOURCE_DIR: Directory containing .jpg files to organize"
    echo "TARGET_DIR: Optional destination directory (defaults to 'PSP_Organized' in SOURCE_DIR)"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/comic/pages              # Basic organization"
    echo "  $0 -c /path/to/comic/pages           # Comic book mode"
    echo "  $0 -c -v /src /dst                   # Comic mode with verbose output"
    echo "  $0 -c -b /comics/library             # Process multiple comics"
}

# Default settings
COMIC_MODE=false
PRESERVE_DATES=false
VERBOSE=false
SOURCE_DIR=""
TARGET_DIR=""
BATCH_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--comic-mode)
            COMIC_MODE=true
            shift
            ;;
        -p|--preserve-dates)
            PRESERVE_DATES=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -b|--batch)
            BATCH_MODE=true
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

# Validate source directory
if [[ -z "$SOURCE_DIR" ]]; then
    echo "Error: Source directory is required"
    show_usage
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist"
    exit 1
fi

# Set default target directory if not provided
if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="$SOURCE_DIR/PSP_Organized"
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Function to log messages
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "$@"
    fi
}

# Function to organize files
organize_files() {
    local source="$1"
    local target="$2"

    log "Scanning directory: $source"
    log "Target directory: $target"

    # Find all .jpg files and sort by modification time
    local jpg_files
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use ls with time sorting (more reliable for PSP compatibility)
        jpg_files=$(ls -t "$source"/*.jpg "$source"/*.JPG 2>/dev/null | head -1000)
    else
        # Linux - use ls with time sorting
        jpg_files=$(ls -t "$source"/*.jpg "$source"/*.JPG 2>/dev/null | head -1000)
    fi

    if [[ -z "$jpg_files" ]]; then
        echo "No .jpg files found in $source"
        return 0
    fi

    log "Found $(echo "$jpg_files" | wc -l) .jpg files"

    # Create organized files
    local counter=1
    local total_files=$(echo "$jpg_files" | wc -l)

    echo "Organizing $total_files files..."

    while IFS= read -r file; do
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
    done <<< "$jpg_files"

    echo "Successfully organized $((counter-1)) files to $target"
}

# Function to process batch mode (multiple subdirectories)
process_batch() {
    local source="$1"
    local target="$2"

    echo "Batch processing mode enabled"
    echo "Processing subdirectories as separate comics..."

    # Find all subdirectories (excluding hidden ones)
    local subdirs
    subdirs=$(find "$source" -type d -not -path "$source" -not -path "*/.*")

    if [[ -z "$subdirs" ]]; then
        echo "No subdirectories found in $source"
        return 0
    fi

    local total_dirs=$(echo "$subdirs" | wc -l)
    echo "Found $total_dirs subdirectories to process"

    local processed_count=0

    while IFS= read -r subdir; do
        if [[ -d "$subdir" ]]; then
            local dir_name=$(basename "$subdir")
            local target_subdir="$target/$dir_name"

            log "Processing subdirectory: $dir_name"

            # Check if this subdirectory has .jpg files
            if find "$subdir" -maxdepth 1 -name "*.jpg" -o -name "*.JPG" | head -1 | grep -q "\.jpg"; then
                mkdir -p "$target_subdir"
                organize_files "$subdir" "$target_subdir"
                ((processed_count++))
            else
                log "No .jpg files in $dir_name, skipping"
            fi
        fi
    done <<< "$subdirs"

    echo "Batch processing complete: $processed_count directories processed"
}

# Main execution
echo "PSP Photo Organizer"
echo "==================="

# Check if we're in comic mode
if [[ "$COMIC_MODE" == true ]]; then
    echo "Mode: Comic Book (sequential numbering)"
else
    echo "Mode: Photo Collection (date-based)"
fi

# Check if we're in batch mode
if [[ "$BATCH_MODE" == true ]]; then
    echo "Mode: Batch processing (multiple comics)"
fi

# Organize files
if [[ "$BATCH_MODE" == true ]]; then
    process_batch "$SOURCE_DIR" "$TARGET_DIR"
else
    organize_files "$SOURCE_DIR" "$TARGET_DIR"
fi

echo ""
echo "Done! Files organized in: $TARGET_DIR"
echo ""

if [[ "$BATCH_MODE" == true ]]; then
    echo "For PSP use (Batch Mode):"
    echo "1. Copy the '$TARGET_DIR' folder to your PSP's memory stick"
    echo "2. Each subdirectory will appear as a separate comic/photo album"
    echo "3. Look for them in the 'Photo' section of your PSP"
    echo "4. Files within each folder are sorted by creation date"
else
    echo "For PSP use:"
    echo "1. Copy the '$TARGET_DIR' folder to your PSP's memory stick"
    echo "2. Look for it in the 'Photo' section of your PSP"
    echo "3. Files should appear in the correct order based on creation dates"
fi

if [[ "$COMIC_MODE" == true ]]; then
    echo ""
    echo "Comic Book Notes:"
    echo "- Files are renamed as 001.jpg, 002.jpg, etc. for sequential reading"
    echo "- PSP will display them in numerical order"
    echo "- Perfect for reading comic books page by page"
fi

if [[ "$BATCH_MODE" == true ]]; then
    echo ""
    echo "Batch Mode Notes:"
    echo "- Each subdirectory becomes a separate photo album"
    echo "- Subdirectories without .jpg files are skipped"
    echo "- Great for organizing multiple comics in one operation"
fi
