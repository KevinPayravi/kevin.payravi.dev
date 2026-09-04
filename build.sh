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

# When the CV last changed
CV_UPDATED="$(git log -1 --format=%cd --date=format:'%B %Y' -- "$SRC_DIR/cv/index.html" 2>/dev/null || true)"
CV_UPDATED="${CV_UPDATED:-$(date '+%B %Y')}"

# Read template files
echo "Loading templates..."
TEMPLATE_FILES=()
for template_file in "$TEMPLATES_DIR"/*.html; do
    if [[ -f "$template_file" ]]; then
        template_name=$(basename "$template_file" .html)
        TEMPLATE_FILES+=("$template_name")
        # Export each template with a safe name
        export "TEMPLATE_${template_name}=$(cat "$template_file")"
        echo "  Loaded: $template_name"
    fi
done

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
    local content
    content=$(cat "$src_file")
    content="${content//\{\{CV_UPDATED\}\}/$CV_UPDATED}"
    
    # Process head template
    local head_var="TEMPLATE_head"
    local head_replaced="${!head_var}"
    head_replaced="${head_replaced//\{\{FAVICON_PATH\}\}/$favicon_path}"
    head_replaced="${head_replaced//\{\{CSS_PATH\}\}/$css_path}"
    head_replaced="${head_replaced//\{\{BASE_PATH\}\}/$base_path}"
    export TEMPLATE_head_PROCESSED="$head_replaced"
    
    # Process nav template
    local nav_var="TEMPLATE_nav"
    local nav_replaced="${!nav_var}"
    nav_replaced="${nav_replaced//\{\{BASE_PATH\}\}/$base_path}"
    nav_replaced="${nav_replaced//\{\{CSS_PATH\}\}/$css_path}"
    
    # Mark the current section first, then clear other placeholders
    if [[ "$active_section" != "NONE" ]]; then
        nav_replaced="${nav_replaced//\{\{${active_section}_ACTIVE\}\}/selected\" aria-current=\"page}"
    fi

    local -a nav_states=("HOME" "ABOUT" "CV" "PORTFOLIO" "RESOURCES" "CONTACT")
    for state in "${nav_states[@]}"; do
        nav_replaced="${nav_replaced//\{\{${state}_ACTIVE\}\}/}"
    done
    export TEMPLATE_nav_PROCESSED="$nav_replaced"
    
    # Export template names list (space-separated)
    export TEMPLATE_NAMES="${TEMPLATE_FILES[*]}"
    
    # Replace data-template attributes dynamically using Perl
    echo "$content" | perl -0777 -pe '
        # Get template names from environment
        my @template_names = split(/ /, $ENV{TEMPLATE_NAMES});
        
        # Replace each template dynamically
        foreach my $name (@template_names) {
            # Check if there is a processed version first (for head/nav)
            my $template_content = $ENV{"TEMPLATE_${name}_PROCESSED"};
            # Fall back to original if no processed version exists
            $template_content = $ENV{"TEMPLATE_$name"} unless $template_content;
            
            # Determine the appropriate HTML tag for this template
            my $tag = "div";
            $tag = "nav" if $name eq "nav";
            $tag = "footer" if $name eq "footer";
            
            # Replace the template placeholder
            s|<$tag[^>]*data-template=["'"'"']$name["'"'"'][^>]*>.*?</$tag>|$template_content|gs;
        }
    ' > "$dest_file"

    # Inline stylesheet for 404.html
    if [[ "$src_file" == "$SRC_DIR/404.html" ]]; then
        CSS_CONTENT="$(cat css/style.css)" perl -0pi -e 's|<link rel="stylesheet" type="text/css" href="/css/style.css" />|<style>\n$ENV{CSS_CONTENT}\n</style>|' "$dest_file"
    fi
    
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

# Render the CV page to PDF
build_cv_pdf() {
    local chrome=""
    local candidate
    for candidate in "${CHROME_BIN:-}" google-chrome \
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
        if [[ -n "$candidate" ]] && command -v "$candidate" >/dev/null 2>&1; then
            chrome="$candidate"
            break
        fi
    done
    if [[ -z "$chrome" ]]; then
        echo "Error: CV PDF needs Chrome and none was found (set CHROME_BIN)" >&2
        exit 1
    fi

    mkdir -p "$BUILD_DIR/docs"
    local -r cv_dir="$(cd "$BUILD_DIR/cv" && pwd)"
    local -r docs_dir="$(cd "$BUILD_DIR/docs" && pwd)"

    # Prepare print-friendly version of CV
    sed -e 's|<body>|<body class="resume">|' \
        -e 's|<title>CV - Kevin Payravi</title>|<title>Résumé - Kevin Payravi</title>|' \
        "$cv_dir/index.html" > "$cv_dir/resume-print.html"

    # --no-sandbox: local file
    local page out name
    for name in cv resume; do
        page="file://$cv_dir/index.html"
        [[ "$name" == "resume" ]] && page="file://$cv_dir/resume-print.html"
        out="$docs_dir/$name.pdf"
        rm -f "$out"
        "$chrome" --headless --disable-gpu --no-sandbox \
            --no-pdf-header-footer --export-tagged-pdf --generate-pdf-document-outline \
            --print-to-pdf="$out" "$page" >/dev/null 2>&1 || true
        if [[ ! -s "$out" ]]; then
            echo "Error: $name.pdf was not generated" >&2
            exit 1
        fi
        echo "Built: $BUILD_DIR/docs/$name.pdf"
    done
    rm -f "$cv_dir/resume-print.html"
}

echo ""
echo "Rendering CV PDF..."
build_cv_pdf

# Copy 404.html if it exists
if [[ -f "404.html" ]]; then
    cp "404.html" "$BUILD_DIR/"
    echo "Copied: 404.html"
fi

echo ""
echo "✓ Build completed successfully!"
