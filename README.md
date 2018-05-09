# Fast Color Deconvolution for histological images with Mathematica

This package provides a fast implementation of the Color Deconvolution algorithm by Ruifrok and Johnson [1].
For adjusting staining vectors, the package provides a dynamic tool that lets you adjust and inspect the quality of deconvolution results which bases on the work of Gilbert Bigras [2].
The `ColorDeconvolution` will happily work with even very large histological images.

## Introduction

Color Deconvolution is a method that extracts stain intensities from histological RGB images.
To obtain meaningful results, the staining needs to follow the 
[Beer-Lambert law](https://en.wikipedia.org/wiki/Beer%E2%80%93Lambert_law)
and therefore, that the absorbance of the single dyes are proportional to their concentration.

Therefore, a microscopic image of a stained histological section follows the process of white light that is transmitted
through the section and each dye absorbs a characteristic portion that depends on the concentration of the dye and its color.
Using the characteristic color-vectors for the staining, this operation can be inverted and result are intensity-images
for each used dye.

To obtain excellent results, each step in the process of acquiring an image must be carefully revised to ensure 
consistent lighting, white-balance, and correct camera settings. A basic tutorial can be found in 
["How to correct background illumination in brightfield microscopy"](http://imagejdocu.tudor.lu/doku.php?id=howto:working:how_to_correct_background_illumination_in_brightfield_microscopy).

## Performance

The color deconvolution algorithm itself is rather simple, but it consists of two sub-functions functions that are computational expensive on large images.
The first one is the computation of the optical density image from your original image and after that, the calculation of the deconvolution image.
Both functions, however, can be applied in parallel on each pixel and the implementation here makes use of it.

For optimal performance, you should have a working C compiler on your system and you should ensure, that Mathematica can use it to create optimized code. Your compiler works and can be used by Mathematica if the following snippet runs without error

```mathematica
Compile[{}, 1, CompilationTarget -> "C"][]
``` 

If a compiler is not available, the package will use Mathematica's virtual machine automatically.
The parallel performance depends on the number of cores you have and how many parallel threads are used by Mathematica.
You can check your number of cores by running

```mathematica
$ProcessorCount
(* 12 *)
```
and the number of parallel threads by running

```mathematica
SystemOptions["ParallelOptions" -> "ParallelThreadNumber"]

(* {"ParallelOptions" -> {"ParallelThreadNumber" -> 12}} *)
```

The following shows the running-time of the `ColorDeconvolution` on with an image of size 2048 x 2048 on a Mac Pro 2,7 GHz 12-Core Intel Xeon E5.

![performance](http://i.stack.imgur.com/Ljj81.png)

## Other Implementations

There are certain other implementations for color deconvolution. The [plugin for ImageJ](https://imagej.net/Colour_Deconvolution)
by Gabriel Landini is well known and its preset of color vectors is included in this package.
Jakob Nikolas Kather provided [a package for MATLAB](https://github.com/jnkather/ColorDeconvolutionMatlab)
and refers to two other MATLAB implementations whose sites seem to be down.

## References

- [1] [Ruifrok, A.C. & Johnston, D.A. (2001), "Quantification of histochemical staining by color deconvolution", Anal. Quant. Cytol. Histol. 23: 291-299, PMID 11531144](https://www.ncbi.nlm.nih.gov/pubmed/11531144)
- [2] [Bigras, G. "Quantification of histochemical staining by color deconvolution", Anal Quant Cytol Histol. 2012 Jun;34(3):149-60.](https://www.ncbi.nlm.nih.gov/pubmed/23016461) 
