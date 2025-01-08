<?php

// For each frames in frames/*.png .... 
$frames = glob('frames/*.png');
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

	echo "Processing $frame";
	// Be silly many times
	for($i = 0; $i < 100; $i++) {
		imagejpeg($image, $tmp, rand(2,100));
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
	// imagefilter($image, IMG_FILTER_GRAYSCALE);

	imagedestroy($image);
}

