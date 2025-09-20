#!/bin/bash

# Prompt for input directory
read -p "Enter the full path of the directory with images: " dir

# Check if directory exists
if [ ! -d "$dir" ]; then
  echo "Error: Directory does not exist."
  exit 1
fi

# Move into directory
cd "$dir" || exit 1

# Create compressed output folder
outdir="compressed"
mkdir -p "$outdir"

echo "Checking for image files in: $dir"
shopt -s nullglob
files=(*.jpg *.jpeg *.png *.webp *.gif *.bmp)

if [ ${#files[@]} -eq 0 ]; then
  echo "No supported image files (.jpg, .jpeg, .png, .webp, .gif, .bmp) found."
  exit 0
fi

echo "Found ${#files[@]} image(s). Converting to JPG if needed..."

# Convert non-JPG files to JPG
for f in *.png *.webp *.gif *.bmp; do
  [ -e "$f" ] || continue
  base="${f%.*}"
  echo "Converting: $f → $base.jpg"
  magick "$f" "$base.jpg"
done

# Now compress all JPGs into the output folder
echo "Compressing JPG files..."
mogrify -path "$outdir" -format jpg -quality 80 -strip -sampling-factor 4:2:0 *.jpg

echo "Done! All files saved as JPG in: $dir/$outdir"
