#!/usr/bin/env bash

# Simple static site builder via shell script

set -euo pipefail

# Configuration
readonly SRC_DIR="src"
readonly TEMPLATES_DIR="templates"
readonly BUILD_DIR="build"
readonly STATIC_DIRS=("css" "scripts" "images" "icons" "webfonts" "docs")

echo "Starting build..."
echo ""

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Read template files
echo "Loading templates..."
readonly HEAD_TEMPLATE=$(cat "$TEMPLATES_DIR/head.html")
readonly NAV_TEMPLATE=$(cat "$TEMPLATES_DIR/nav.html")
readonly FOOTER_TEMPLATE=$(cat "$TEMPLATES_DIR/footer.html")

# Function to get depth of file (for path calculation)
get_depth() {
    local -r file="$1"
    local -r relative="${file#$SRC_DIR/}"
    grep -o "/" <<< "$relative" | wc -l | tr -d ' '
}

# Function to get base path
get_base_path() {
    local -r depth=$1
    if [[ "$depth" -eq 0 ]]; then
        echo "./"
    else
        printf '../%.0s' $(seq 1 "$depth")
    fi
}

# Function to get active nav state
get_nav_state() {
    local -r file="$1"
    local -r section=$(dirname "${file#$SRC_DIR/}")
    
    if [[ "$file" == "$SRC_DIR/index.html" ]]; then
        echo "HOME"
    elif [[ "$section" == *"about"* ]]; then
        echo "ABOUT"
    elif [[ "$section" == *"cv"* ]]; then
        echo "CV"
    elif [[ "$section" == *"portfolio"* ]]; then
        echo "PORTFOLIO"
    elif [[ "$section" == *"resources"* ]]; then
        echo "RESOURCES"
    elif [[ "$section" == *"contact"* ]]; then
        echo "CONTACT"
    else
        echo "NONE"
    fi
}

# Function to process an HTML file
process_file() {
    local -r src_file="$1"
    local -r dest_file="${src_file/$SRC_DIR/$BUILD_DIR}"
    
    # Create destination directory
    mkdir -p "$(dirname "$dest_file")"
    
    # Calculate paths
    local -r depth=$(get_depth "$src_file")
    local -r base_path=$(get_base_path "$depth")
    local -r css_path="${base_path}css/"
    local -r favicon_path="${base_path}icons/favicons/user.ico"
    
    # Get active nav state
    local -r active_section=$(get_nav_state "$src_file")
    
    # Read source file
    local -r content=$(cat "$src_file")
    
    # Prepare templates with variables
    local head_replaced="$HEAD_TEMPLATE"
    head_replaced="${head_replaced//\{\{FAVICON_PATH\}\}/$favicon_path}"
    head_replaced="${head_replaced//\{\{CSS_PATH\}\}/$css_path}"
    head_replaced="${head_replaced//\{\{BASE_PATH\}\}/$base_path}"
    
    local nav_replaced="$NAV_TEMPLATE"
    nav_replaced="${nav_replaced//\{\{BASE_PATH\}\}/$base_path}"
    nav_replaced="${nav_replaced//\{\{CSS_PATH\}\}/$css_path}"
    
    # Set active nav states (clear all first)
    local -a nav_states=("HOME" "ABOUT" "CV" "PORTFOLIO" "RESOURCES" "CONTACT")
    for state in "${nav_states[@]}"; do
        nav_replaced="${nav_replaced//\{\{${state}_ACTIVE\}\}/}"
    done
    
    # Set the active state for current section
    if [[ "$active_section" != "NONE" ]]; then
        nav_replaced="${nav_replaced//\{\{${active_section}_ACTIVE\}\}/selected\" aria-current=\"page}"
    fi
    
    # Export templates for Perl to access via environment
    HEAD_TEMPLATE_PROCESSED="$head_replaced"
    NAV_TEMPLATE_PROCESSED="$nav_replaced"
    FOOTER_TEMPLATE_PROCESSED="$FOOTER_TEMPLATE"
    export HEAD_TEMPLATE_PROCESSED NAV_TEMPLATE_PROCESSED FOOTER_TEMPLATE_PROCESSED
    
    # Replace data-template attributes and HTML comments using Perl
    echo "$content" | perl -0777 -pe '
        # Get templates from shell environment
        my $head = $ENV{HEAD_TEMPLATE_PROCESSED};
        my $nav = $ENV{NAV_TEMPLATE_PROCESSED};
        my $footer = $ENV{FOOTER_TEMPLATE_PROCESSED};
        
        # Replace data-template attributes
        s|<div[^>]*data-template=["'"'"']head["'"'"'][^>]*>.*?</div>|$head|gs;
        s|<nav[^>]*data-template=["'"'"']nav["'"'"'][^>]*>.*?</nav>|$nav|gs;
        s|<footer[^>]*data-template=["'"'"']footer["'"'"'][^>]*>.*?</footer>|$footer|gs;
    ' > "$dest_file"
    
    echo "Built: $dest_file"
}

# Process all HTML files
echo ""
echo "Processing HTML files..."

# Function to process directory recursively
process_directory() {
    local -r dir="$1"
    
    for file in "$dir"/*; do
        if [[ -d "$file" ]]; then
            process_directory "$file"
        elif [[ "$file" == *.html ]]; then
            process_file "$file"
        fi
    done
}

if [[ -d "$SRC_DIR" ]]; then
    process_directory "$SRC_DIR"
else
    echo "Error: Source directory '$SRC_DIR' not found!" >&2
    exit 1
fi

# Copy static files
echo ""
echo "Copying static files..."
for dir in "${STATIC_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        cp -r "$dir" "$BUILD_DIR/"
        echo "Copied: $dir/"
    fi
done

# Copy 404.html if it exists
if [[ -f "404.html" ]]; then
    cp "404.html" "$BUILD_DIR/"
    echo "Copied: 404.html"
fi

echo ""
echo "✓ Build completed successfully!"
