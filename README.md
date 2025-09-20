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

### Step 1: Set Timestamps for PSP Compatibility (Important!)
```bash
# Set 1-minute increments between files starting from midnight today
./set_timestamps.sh ~/path/to/your/images

# Or set a specific start time
./set_timestamps.sh -s "2025-01-01 12:00" ~/path/to/your/images
```

### Step 2: Organize Files

### Basic Usage
```bash
./organize_for_psp.sh /path/to/your/images
```

### Comic Book Mode (Recommended for Comics)
```bash
./organize_for_psp.sh -c /path/to/comic/pages
```

### Batch Mode (Multiple Comics)
```bash
./organize_for_psp.sh -c -b /path/to/comics/library
```

### Full Options
```bash
./organize_for_psp.sh [OPTIONS] SOURCE_DIR [TARGET_DIR]

Options:
  -h, --help          Show help message
  -c, --comic-mode    Enable comic book mode (sequential numbering)
  -p, --preserve-dates Preserve original file dates
  -v, --verbose       Verbose output
  -b, --batch         Process subdirectories as separate comics
```

## Examples

### Single Comic Book
```bash
# Organize pages of a single comic book
./organize_for_psp.sh -c ~/Downloads/Comic_Book_Pages
```

### Multiple Comic Books
```bash
# Process a library of comic books (each subdirectory becomes an album)
./organize_for_psp.sh -c -b ~/Downloads/Comic_Library
```

### Photo Collection
```bash
# Organize regular photos by date
./organize_for_psp.sh ~/Pictures/Vacation_Photos
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
