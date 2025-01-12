#!/bin/bash

# if directories frames / audio exist, confirm deletion Y/n and if Y delete em
if [ -d "src/frames" ] || [ -d "src/audio" ]; then
	read -p "Directories 'frames' and 'audio' already exist. Do you want to delete them? (Y/n) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		rm -r src/frames src/audio
	else
		echo "Exiting..."
		exit 1
	fi
fi

# Check if a video file was provided
if [ $# -ne 1 ] && [ $# -ne 2 ]; then
    echo "Usage: $0 <video_file> <loops:optional>"
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


# Create necessary directories
mkdir -p src/frames
mkdir -p src/audio
mkdir -p output

# if we have a second parameter, that is number of loops, otherwise default to 1 loop
if [ $# -eq 2 ]; then
	loops=$2
else
	loops=1
fi

# Get video framerate
framerate=$(ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate "$input_video" | bc -l)
echo "Detected framerate: $framerate fps"

echo "----------------------------------------"

# run each loop
for (( i=0; i<$loops; i++ ))
do

	echo "Processing video loop: $((i + 1))/$loops"

	filename="${basename%.*}_${timestamp}_${i}"


	# echo "Processing video loop: $((i + 1))/$loops"
	# # if we are looping we will start with the output video as the input
	if [ $i -gt 0 ]; then
		input_video=$output_video
	fi

	echo " ${input_video} ${output_video}\n"

	output_video="output/${filename}.mp4"

	# # Extract audio (all streams)
	ffmpeg -i "$input_video" -vn -acodec copy "src/audio/audio_track_${timestamp}_${i}.aac" 2>/dev/null

	# # Extract frames as PNG
	ffmpeg -i "$input_video" -vsync "0" "src/frames/frame_${timestamp}_%08d_${i}.png"

	# echo "----------------------------------------"
	# echo "Processing frames..."
	# # echo "This is where you would add your frame processing logic"
	# # echo "Process all PNG files in ./frames/ directory"

	# # Run the filter script(s)
	php filter.php $timestamp 50

	# echo "----------------------------------------"
	# echo "Processing complete!"
	# echo "----------------------------------------"
	# # Reconstruct video with processed frames
	# # Note: Adjust -r parameter to match original framerate
	ffmpeg -r "$framerate" -i "src/frames/frame_${timestamp}_%08d_${i}.png" -i "src/audio/audio_track_${timestamp}_${i}.aac" \
	    -c:v libx264 -pix_fmt yuv420p -preset medium -crf 23 \
	    -c:a aac -b:a 192k \
	    -movflags +faststart \
	    "$output_video"

	# if this is a loop > 1
	#  concatinate the output video after the input video, and write to a new file
	if [ $i -eq 0 ]; then
		cp $output_video output/merged.mp4
	fi

	# add to the end of the outout thing
	if [ $i -gt 0 ]; then
		ffmpeg -i "output/merged.mp4" -i "$output_video" -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" "output/merged-temp.mp4"
		cp output/merged-temp.mp4 output/merged.mp4 # move back over to the main file
		rm output/merged-temp.mp4
	fi

	# clean up old frames, audio
	rm -r src/frames/*.png src/audio/*.aac

done

# Clean up the tmp dir
rm -r src

echo "Video processing complete!"
echo "Output saved as: $output_video"

open -R "$output_video"

# Optional cleanup
# rm -r frames audio

# Exit successfully
exit 0
