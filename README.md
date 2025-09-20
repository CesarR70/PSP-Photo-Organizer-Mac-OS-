# PSP Photo Organizer

A macOS shell script to organize .jpg files for optimal viewing on PlayStation Portable (PSP) devices.

## About PSP Image Organization

PSP devices organize images primarily by:
- **File creation/modification dates** (most important)
- **Sequential file ordering** when dates are the same
- **EXIF metadata** if available

The PSP Photo application displays images in chronological order based on file timestamps, not filenames.

⚠️ **Important**: PSP can only distinguish files by **minute-level granularity**. If multiple files have timestamps within the same minute, PSP may not sort them correctly. Use the included `set_timestamps.sh` script to set 1-minute increments for best PSP compatibility.

## Features

- **Date-based sorting**: Organizes files by creation date for proper PSP viewing order
- **Comic book mode**: Sequential numbering (001.jpg, 002.jpg, etc.) for comic books
- **Batch processing**: Handle multiple comic books/subdirectories at once
- **Preserve dates**: Option to maintain original file timestamps
- **macOS optimized**: Uses macOS-specific commands for accurate date sorting
- **PSP timestamp compatibility**: `set_timestamps.sh` sets 1-minute increments for PSP compatibility

## Usage

### Complete Solution (Recommended)
Use the new unified script that combines all functionality:

```bash
# Full pipeline: convert, organize, and set timestamps
./psp_photo_organizer.sh /path/to/your/images

# Comic book mode with timestamps
./psp_photo_organizer.sh -c -t /path/to/comic/pages

# Batch processing multiple comics with all features
./psp_photo_organizer.sh -c -b -t /path/to/comics/library

# Custom settings
./psp_photo_organizer.sh -v -q 85 -s "2025-01-01 12:00" /images
```

### Individual Scripts (Legacy)
The original scripts are still available for specific use cases:

#### Step 1: Convert Images (Optional)
```bash
# Convert various image formats to JPG and compress
./01-jpg_convert_compress.sh
```

#### Step 2: Set Timestamps for PSP Compatibility (Important!)
```bash
# Set 1-minute increments between files starting from yesterday at midnight
./03-set_timestamps.sh ~/path/to/your/images

# Or set a specific start time
./03-set_timestamps.sh -s "2025-01-01 12:00" ~/path/to/your/images
```

#### Step 3: Organize Files
```bash
# Basic organization
./02-organize_for_psp.sh /path/to/your/images

# Comic book mode (Recommended for Comics)
./02-organize_for_psp.sh -c /path/to/comic/pages

# Batch mode (Multiple Comics)
./02-organize_for_psp.sh -c -b /path/to/comics/library
```

### Unified Script Options
```bash
./psp_photo_organizer.sh [OPTIONS] SOURCE_DIR [TARGET_DIR]

Options:
  -h, --help              Show this help message
  -v, --verbose           Verbose output
  -c, --comic-mode        Enable comic book mode (sequential numbering)
  -b, --batch             Process subdirectories as separate comics
  -p, --preserve-dates    Preserve original file dates during organization
  -t, --timestamps        Set 1-minute increment timestamps for PSP compatibility
  -s, --start-time TIME   Start time for timestamps (YYYY-MM-DD HH:MM, defaults to yesterday midnight)
  -q, --quality PERCENT   JPG quality for conversion (default: 80)
  --no-convert            Skip image conversion step
```

## Examples

### Single Comic Book
```bash
# Complete processing: convert, organize as comic, and set timestamps
./psp_photo_organizer.sh -c -t ~/Downloads/Comic_Book_Pages
```

### Multiple Comic Books
```bash
# Batch process a library of comic books with full optimization
./psp_photo_organizer.sh -c -b -t ~/Downloads/Comic_Library
```

### Photo Collection
```bash
# Organize regular photos with PSP timestamp optimization
./psp_photo_organizer.sh -t ~/Pictures/Vacation_Photos
```

### Advanced Usage
```bash
# High quality conversion with custom timestamp start
./psp_photo_organizer.sh -v -q 90 -s "2025-01-01 10:00" ~/Pictures/Photos

# Comic mode with timestamps, no conversion (already JPG)
./psp_photo_organizer.sh -c -t --no-convert ~/Already_JPG_Comic

# Batch processing with verbose output
./psp_photo_organizer.sh -c -b -t -v ~/Comic_Library
```

## For PSP Use

1. **Copy the organized folder** to your PSP's memory stick
2. **Navigate to Photo** in the PSP menu
3. **Browse to your folder** - files will appear in correct chronological order
4. **For comics**: Pages will be numbered sequentially (001.jpg, 002.jpg, etc.)

## Comic Book Specific Notes

- Files are renamed as `001.jpg`, `002.jpg`, etc. for sequential reading
- PSP displays files in numerical order
- Perfect for reading comic books page by page
- Each subdirectory in batch mode becomes a separate photo album

## Technical Details

- Uses `stat` command to get file creation times
- Sorts files by birth time (creation date)
- Preserves file metadata when using `-p` flag
- Creates organized copies (originals remain unchanged)

## Testing

Run the included test script to see how it works:
```bash
./test_script.sh
```

This creates sample files with different timestamps to demonstrate the sorting functionality.
