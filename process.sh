#!/bin/bash

# if directories frames / audio exist, confirm deletion Y/n and if Y delete em
if [ -d "frames" ] || [ -d "audio" ]; then
	read -p "Directories 'frames' and 'audio' already exist. Do you want to delete them? (Y/n) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		rm -r frames audio
	else
		echo "Exiting..."
		exit 1
	fi
fi

# Check if a video file was provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <video_file>"
    exit 1
fi

# Check if the provided file exists
if [ ! -f "$1" ]; then
	echo "Error: File not found!"
	exit 1
fi

input_video="$1"
timestamp=$(date +%Y%m%d%H%M%S)
basename=$(basename "$input_video")
filename="${basename%.*}"
output_video="output/${filename}.processed.${timestamp}.mp4"

# Create necessary directories
mkdir -p src/frames
mkdir -p src/audio
mkdir -p output

# Get video framerate
framerate=$(ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate "$input_video" | bc -l)
echo "Detected framerate: $framerate fps"

# Extract audio (all streams)
ffmpeg -i "$input_video" -vn -acodec copy "src/audio/audio_track_${timestamp}.aac" 2>/dev/null

# Extract frames as PNG
ffmpeg -i "$input_video" -vsync 0 "src/frames/frame_${timestamp}_%08d.png"

echo "Video processing preparation complete!"
echo "----------------------------------------"
echo "Input video: $input_video"
echo "Frames extracted to: ./frames/"
echo "Audio tracks extracted to: ./audio/"
echo "----------------------------------------"
echo "PROCESSING FRAMES..."
# echo "This is where you would add your frame processing logic"
# echo "Process all PNG files in ./frames/ directory"

# Run the filter script(s)
php filter.php $timestamp




echo "----------------------------------------"
echo "Processing complete!"
echo "----------------------------------------"
# Reconstruct video with processed frames
# Note: Adjust -r parameter to match original framerate
ffmpeg -r "$framerate" -i "src/frames/frame_${timestamp}_%08d.png" -i "src/audio/audio_track_${timestamp}.aac" \
    -c:v libx264 -pix_fmt yuv420p -preset medium -crf 23 \
    -c:a aac -b:a 192k \
    -movflags +faststart \
    "$output_video"

echo "Video processing complete!"
echo "Output saved as: $output_video"

open -R "$output_video"

# Optional cleanup
# rm -r frames audio

# Exit successfully
exit 0