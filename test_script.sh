#!/bin/bash

# Test script for PSP Photo Organizer
# Creates sample .jpg files to test the organizer script

set -e

echo "PSP Photo Organizer - Test Script"
echo "=================================="

# Create test directory structure
TEST_DIR="/tmp/psp_test"
COMIC1_DIR="$TEST_DIR/Comic_Issue_1"
COMIC2_DIR="$TEST_DIR/Comic_Issue_2"

echo "Creating test directory structure..."
mkdir -p "$COMIC1_DIR"
mkdir -p "$COMIC2_DIR"

echo "Creating sample .jpg files..."

# Function to create a sample image file (just a text file renamed as jpg for testing)
create_sample_jpg() {
    local filename="$1"
    local content="$2"
    echo "$content" > "$filename"
}

# Create sample comic book pages with different timestamps
echo "Creating Comic Issue 1 pages..."
create_sample_jpg "$COMIC1_DIR/page1.jpg" "Comic Issue 1 - Page 1"
create_sample_jpg "$COMIC1_DIR/page2.jpg" "Comic Issue 1 - Page 2"
create_sample_jpg "$COMIC1_DIR/page3.jpg" "Comic Issue 1 - Page 3"

echo "Creating Comic Issue 2 pages..."
create_sample_jpg "$COMIC2_DIR/page1.jpg" "Comic Issue 2 - Page 1"
create_sample_jpg "$COMIC2_DIR/page2.jpg" "Comic Issue 2 - Page 2"

echo "Setting different creation times for files..."

# Set different modification times to simulate different creation dates
touch -t 202501010900 "$COMIC1_DIR/page1.jpg"  # Jan 1, 2025 09:00
touch -t 202501010910 "$COMIC1_DIR/page2.jpg"  # Jan 1, 2025 09:10
touch -t 202501010920 "$COMIC1_DIR/page3.jpg"  # Jan 1, 2025 09:20

touch -t 202501020900 "$COMIC2_DIR/page1.jpg"  # Jan 2, 2025 09:00
touch -t 202501020910 "$COMIC2_DIR/page2.jpg"  # Jan 2, 2025 09:10

echo ""
echo "Test files created successfully!"
echo "Directory structure:"
echo "  $TEST_DIR/"
echo "    Comic_Issue_1/"
echo "      page1.jpg (timestamp: Jan 1, 2025 09:00)"
echo "      page2.jpg (timestamp: Jan 1, 2025 09:10)"
echo "      page3.jpg (timestamp: Jan 1, 2025 09:20)"
echo "    Comic_Issue_2/"
echo "      page1.jpg (timestamp: Jan 2, 2025 09:00)"
echo "      page2.jpg (timestamp: Jan 2, 2025 09:10)"
echo ""

echo "Now you can test the organizer script with:"
echo "  ./organize_for_psp.sh -c -b -v $TEST_DIR"
echo ""
echo "This will:"
echo "  - Use comic mode (-c) for sequential numbering"
echo "  - Use batch mode (-b) to process subdirectories"
echo "  - Use verbose mode (-v) to see detailed output"
echo ""

echo "The script will create organized files in: $TEST_DIR/PSP_Organized/"
echo "Each comic will have its own folder with pages numbered 001.jpg, 002.jpg, etc."

