#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick is not installed. Installing via Homebrew..."
    brew install imagemagick
fi

# Function to get image dimensions
get_dimensions() {
    identify -format "%wx%h" "$1"
}

# Function to get image width
get_width() {
    identify -format "%w" "$1"
}

# Function to get image height
get_height() {
    identify -format "%h" "$1"
}

# Function to display usage
usage() {
    echo "Usage: $0 [-s size] input_file [output_file]"
    echo "Options:"
    echo "  -s    Maximum size in pixels for the longest dimension"
    echo "Examples:"
    echo "  $0 -s 800 large.jpg              # Outputs resized-large.jpg"
    echo "  $0 -s 1200 input.jpg output.jpg  # Specific output filename"
    exit 1
}

# Default values
MAX_SIZE=800
QUALITY=85

# Parse command line arguments
while getopts "s:h" opt; do
    case $opt in
        s) MAX_SIZE="$OPTARG";;
        h) usage;;
        ?) usage;;
    esac
done

# Shift off the options
shift $((OPTIND-1))

# Check if input file is provided
if [ $# -lt 1 ]; then
    usage
fi

INPUT_FILE="$1"
if [ $# -eq 2 ]; then
    OUTPUT_FILE="$2"
else
    # Generate output filename if not provided
    FILENAME=$(basename "$INPUT_FILE")
    EXTENSION="${FILENAME##*.}"
    BASENAME="${FILENAME%.*}"
    OUTPUT_FILE="resized-${BASENAME}.${EXTENSION}"
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Get original dimensions
WIDTH=$(get_width "$INPUT_FILE")
HEIGHT=$(get_height "$INPUT_FILE")
ORIGINAL_DIMS="${WIDTH}x${HEIGHT}"

echo "Processing: $INPUT_FILE"
echo "Original dimensions: $ORIGINAL_DIMS"

# Only resize if image is larger than MAX_SIZE
if [ "$WIDTH" -gt "$MAX_SIZE" ] || [ "$HEIGHT" -gt "$MAX_SIZE" ]; then
    # Use the larger dimension to determine scaling
    if [ "$WIDTH" -gt "$HEIGHT" ]; then
        RESIZE_DIMS="${MAX_SIZE}x"
    else
        RESIZE_DIMS="x${MAX_SIZE}"
    fi
    
    convert "$INPUT_FILE" -resize "$RESIZE_DIMS>" -quality "$QUALITY" "$OUTPUT_FILE"
    
    # Verify the resize worked
    NEW_WIDTH=$(get_width "$OUTPUT_FILE")
    NEW_HEIGHT=$(get_height "$OUTPUT_FILE")
    
    if [ "$NEW_WIDTH" -eq "$WIDTH" ] && [ "$NEW_HEIGHT" -eq "$HEIGHT" ]; then
        echo "Warning: Image dimensions did not change!"
        echo "This might be due to image format limitations or other issues."
        exit 1
    fi
    
    # Get file sizes
    ORIGINAL_SIZE=$(ls -lh "$INPUT_FILE" | awk '{print $5}')
    NEW_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    
    echo "Resize complete!"
    echo "New dimensions: ${NEW_WIDTH}x${NEW_HEIGHT}"
    echo "Original size: $ORIGINAL_SIZE"
    echo "New size: $NEW_SIZE"
else
    echo "Image is already smaller than ${MAX_SIZE}px in both dimensions."
    echo "No resize needed."
fi