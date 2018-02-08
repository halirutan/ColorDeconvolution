# Histological Color Deconvolution for Mathematica

Color Deconvolution is a method that extracts stain intensities from histological RGB images.
To obtain meaningful results, the staining needs to follow the 
[Beer-Lambert law](https://en.wikipedia.org/wiki/Beer%E2%80%93Lambert_law)
and therefore, that the absorbance of the single dyes are proportional to their concentration.

Therefore, a microscopic image of a stained histological section follows the process of white light that is transmitted
through the section and each dye absorbs a characteristic portion that depends on the concentration of the dye and its color.
Using the characteristic color-vectors for the staining, this operation can be inverted and result are intensity-images
for each used dye.

To obtain excellent results, each step in the process of acquiring an image must be carefully revised to ensure 
consistent lighting, white-balance, and correct camera settings. A fine tutorial can be found in 
["How to correct background illumination in brightfield microscopy"](http://imagejdocu.tudor.lu/doku.php?id=howto:working:how_to_correct_background_illumination_in_brightfield_microscopy).