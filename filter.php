<?php

// get the first cli argument as the expected timestamp in the naming convention
$timestamp = $argv[1];
$loops = $argv[2];

// For each frames in frames/*.png .... 
$frames = glob("src/frames/frame_{$timestamp}*.png");
foreach ($frames as $frame) {

	echo "Applying filter to $frame\n";
	// ... apply the filter to the frame
	$image = imagecreatefrompng($frame);
	if ($image === false) {
		echo "Failed to create image from $frame\n";
		continue;
	}
	// write to a temp file as a jpeg at 50 quality
	$tmp = "work.jpg";

	$low = rand(1,100);
	$high = rand($low,100);

	echo "Processing $frame";
	// Be silly many times
	for($i = 0; $i < $loops; $i++) {
		imagejpeg($image, $tmp, rand($low,$high));
		// read it back in and save as a png
		$image = imagecreatefromjpeg($tmp);
		// write it to a temp file as a jpeg at 98 quality
		imagejpeg($image, $tmp, 98);
		// read it back in and save as a png
		$image = imagecreatefromjpeg($tmp);
		echo ".";
	}
	echo "\n";

	imagepng($image, $frame);
	imagedestroy($image);

}

if (is_file($tmp))
	unlink($tmp);
