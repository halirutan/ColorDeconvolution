(* Mathematica Package *)
(* Created by Mathematica Plugin for IntelliJ IDEA *)

(* :Title: ColorDeconvolution *)
(* :Context: ColorDeconvolution` *)
(* :Author: patrick *)
(* :Date: 2017-12-04 *)

(* :Package Version: 0.1 *)
(* :Mathematica Version: *)
(* :Copyright: (c) 2017 patrick *)
(* :Keywords: *)
(* :Discussion: *)

BeginPackage["ColorDeconvolution`"];
(* Exported symbols added here with SymbolName::usage *)

ColorDeconvolution::usage = "ColorDeconvolution[img, Staining[\"stain-name\"]] creates a color deconvolution regarding the colors" <>
    "given in the staining.";
CreateStainingKernel::usage = "CreateStainingKernel[Staining[..]] or CreateStainingKernel[{_Dye, ..}]";
ColorDeconvolutionWhiteImage::usage = "ColorDeconvolutionWhiteImage is an option for ColorDeconvolution. " <>
    "It is used to equalize the brightness and remove incoherent lighting." <>
    "Can be None, Automatic or an Image with the same specification as the input image. " <>
    "Setting None will effectively use a white point of 1. Automatic will try to calculate the brightest point from the image by " <>
    "taking a small sample of pixels. Supplying an Image that was taken with the same Microscope settings works best.";
ColorDeconvolutionBlackImage::usage = "ColorDeconvolutionWhiteImage is an option for ColorDeconvolution. " <>
    "It is used to remove camera pixel defects and should be acquired with the camera light-path closed on the microscope." <>
    "Can be None or an Image with the same specifications as the input image. "
Staining::usage = "Staining[name] a set of predefined stainings";
Dye::usage = "Dye[{r,g,b}] defines the (subtractive) color value for one specific dye. This can included in a Staining, which consists of 1-3 dyes.";

Begin["`Private`"];

$compileTarget = "C";
Quiet[
  Check[
    Compile[{}, 1, CompilationTarget -> $compileTarget],
    $compileTarget = "MVM"
  ]
];

Dye["Hematoxylin"] = Dye[{0.644211, 0.716556, 0.266844}];
Dye["Hematoxylin2"] = Dye[{0.490157, 0.768971, 0.410402}];
Dye["Eosin"] = Dye[{0.092789, 0.954111, 0.283111}];
Dye["Eosin2"] = Dye[{0.490157, 0.768971, 0.410402}];
Dye["Alcian Blue"] = Dye[{0.874622, 0.457711, 0.158256}];
Dye["DAB"] = Dye[{0.268, 0.57, 0.776}];
Dye["PAS"] = Dye[{0.175411, 0.972178, 0.154589}];
Dye["Fast Red"] = Dye[{0.213939, 0.851127, 0.47794}];


Staining["H&E"] = {Dye[{0.644211, 0.716556, 0.266844}], Dye[{0.092789, 0.954111, 0.283111}]};
Staining["H&E 2"] = {Dye[{0.490157, 0.768971, 0.410402}], Dye[{0.0461534, 0.842068, 0.537393}]};
Staining["H DAB"] = {Dye[{0.65, 0.704, 0.286}], Dye[{0.268, 0.57, 0.776}]};
Staining["Feulgen Light Green"] = {Dye[{0.464209, 0.830083, 0.308272}], Dye[{0.947055, 0.253738, 0.196508}]};
Staining["Giemsa"] = {Dye[{0.83475, 0.513556, 0.19633}], Dye[{0.092789, 0.954111, 0.283111}]};
Staining["FastRed FastBlue DAB"] = {Dye[{0.213939, 0.851127, 0.47794}], Dye[{0.748903, 0.606242, 0.267311}], Dye[{0.268, 0.57, 0.776}]};
Staining["Methyl Green DAB"] = {Dye[{0.98, 0.144316, 0.133146}], Dye[{0.268, 0.57, 0.776}]};
Staining["H&E DAB"] = {Dye[{0.65, 0.704, 0.286}], Dye[{0.072, 0.99, 0.105}], Dye[{0.268, 0.57, 0.776}]};
Staining["H AEC"] = {Dye[{0.65, 0.704, 0.286}], Dye[{0.2743, 0.6796, 0.6803}]};
Staining["Azan-Mallory"] = {Dye[{0.853033, 0.508733, 0.112656}], Dye[{0.0928988, 0.866201, 0.490985}], Dye[{0.107328, 0.367654, 0.923748}]};
Staining["Masson Trichrome"] = {Dye[{0.799511, 0.591352, 0.105287}], Dye[{0.0999716, 0.737386, 0.668033}]};
Staining["Alcian Blue & H"] = {Dye[{0.874622, 0.457711, 0.158256}], Dye[{0.552556, 0.7544, 0.353744}]};
Staining["H PAS"] = {Dye[{0.644211, 0.716556, 0.266844}], Dye[{0.175411, 0.972178, 0.154589}]};
Staining["Brilliant Blue"] = {Dye[{0.314655, 0.66024, 0.681965}], Dye[{0.383573, 0.527114, 0.758302}], Dye[{0.743354, 0.517314, 0.42404}]};
Staining["RGB"] = {Dye[{0., 1., 1.}], Dye[{1., 0., 1.}], Dye[{1., 1., 0.}]};
Staining["CMY"] = {Dye[{1., 0., 0.}], Dye[{0., 1., 0.}], Dye[{0., 0., 1.}]};


(* Adding completion for the built-in dye- and staining-names *)
$stainingNames = Keys[DownValues[Staining]][[All, 1, 1]];
$dyeNames = Keys[DownValues[Dye]][[All, 1, 1]];
addCompletions[arg_] := FE`Evaluate[FEPrivate`AddSpecialArgCompletion[arg]];
addCompletions["Dye" -> {$dyeNames}];
addCompletions["Staining" -> {$stainingNames}];

ColorDeconvolutionResult[data_, kernel_]["ColoredImages"] := Null;
ColorDeconvolutionResult[data_, kernel_]["Images"] := Null;
ColorDeconvolutionResult[data_, kernel_]["ColoredImages"] := Null;
ColorDeconvolutionResult[data_, kernel_]["ColoredImages"] := Null;
Format[ColorDeconvolutionResult[data_, __]] := ColorDeconvolutionResult[Dimensions[data]];

validImageQ[img_Image] := ImageChannels[img] === 3 && ImageColorSpace[img] =!= "RGB";
validImageQ[___] := False;

Options[ColorDeconvolution] = {
  ColorDeconvolutionWhiteImage -> None,
  ColorDeconvolutionBlackImage -> None
};

ColorDeconvolution::wimg = "The `` must have 3 channels and in RGB color-space.";
ColorDeconvolution::wimgRef = "The `` must have 3 channels and in RGB color-space and be of the same size than the input image.";
ColorDeconvolution::wstain = "The staining must consist of exactly 3 dyes";
ColorDeconvolution[img_Image, stain : {_Dye..}, opts : OptionsPattern[]] := Module[
  {
    data, kernel, kernelC, whiteImage, blackImage
  },
  If[Not[validImageQ[img]],
    Message[ColorDeconvolution::wimg, "input image"];
    Return[$Failed]
  ];
  If[stain === {} || Length[stain] > 3,
    Message[ColorDeconvolution::wstain];
    Return[$Failed]
  ];

  whiteImage = OptionValue[ColorDeconvolutionWhiteImage];
  If[(whiteImage =!= Automatic || whiteImage =!= None) && !validImageQ[whiteImage] && ImageDimensions[img] =!= ImageDimensions[whiteImage],
    Message[ColorDeconvolution::wimgRef, "White Image"];
    whiteImage = None;
  ];

  blackImage = OptionValue[ColorDeconvolutionBlackImage];
  If[blackImage =!= None && !validImageQ[blackImage] && ImageDimensions[img] =!= ImageDimensions[blackImage],
    Message[ColorDeconvolution::wimgRef, "White Image"];
    blackImage = None
  ];

  data = ImageData[img, "Real", Interleaving -> True];
  kernel = CreateStainingKernel[stain];
  If[kernel =!= $Failed,
    kernelC = compileKernel[kernel];
  ];
  data = iColorDeconvolution[data, kernelC, whiteImage, blackImage];
  ColorDeconvolutionResult[Transpose[data, {2, 3, 1}], stain, kernel]
];

iColorDeconvolution[data_?(TensorQ[#, NumericQ]&), kernel_CompiledFunction, whiteImage_, blackImage_] := Module[
  {
    odData,
    white,
    black
  },
  Switch[
    whiteImage,
    _Image,
    whiteImage = ImageData[whiteImage, "Real", Interleaving -> True],
    Automatic,
    whiteImage = calculateWhitePoint[data],
    None,
    whiteImage = {1.0, 1.0, 1.0}
  ];

  Switch[
    blackImage,
    _Image,
    blackImage = ImageData[blackImage, "Real", Interleaving -> True],
    None,
    blackImage = {0.0, 0.0, 0.0}
  ];
  odData = odC[data, whiteImage, blackImage];
  kernel[odData]
];

ColorDeconvolutionResult[data_List, __][n_ /; 1 <= n <= 3] := Image[data[[n]], "Real"];
ColorDeconvolutionResult[_, od_, _]["OD"] := Image[od, "Real"];
ColorDeconvolutionResult[data_List, _, PrecompiledKernel[_, colors_List]][n_ /; 1 <= n <= 3, Colorize] := colorizeStaining[data[[n]], colors[[n]]];


CompileStainingKernel[stain : {_Dye..}] := Module[
  {
    kernel = FillStainingKernel[stain],
    invKernel,
    result = $Failed
  },
  If[MatrixQ[kernel, NumericQ],
    invKernel = Inverse[kernel];
    If[MatrixQ[invKernel, NumericQ],
      result = PrecompiledKernel[compileKernel[invKernel], Dye /@ kernel]
    ]
  ];
  result
];

VisualiseStaining[PrecompiledKernel[_, stain_]] := VisualiseStaining[stain];
VisualiseStaining[dyes : {_Dye..}] := Graphics[
  Table[{RGBColor[1 - #] & @@ dyes[[i]], Rectangle[{i, 0}]}, {i,
    Length[dyes]}]
];

colorizeStaining[data_, Dye[col_]] := With[
  {
    h = First[ColorConvert[RGBColor[1 - col], "HSB"]]
  },
  Image[
    Compile[{{pixel, _Real, 0}},
      {h, pixel, 1},
      Parallelization -> True,
      RuntimeAttributes -> {Listable}
    ][Rescale@data],
    ColorSpace -> "HSB"
  ]
];

FillStainingKernel::sing = "At least one Dye as only zero entries.";
FillStainingKernel::count = "1-3 colors need to be specified.";
FillStainingKernel[stain : {_Dye}] := FillStainingKernel[Identity @@@ stain];
FillStainingKernel[{vec_?VectorQ}] := With[
  {
    v = Normalize[vec]
  },
  FillStainingKernel[{v, RotateLeft[v]}] /; Norm[v] != 0.0
];
FillStainingKernel[{v1_?VectorQ, v2_?VectorQ}] := With[
  {
    vv1 = Normalize[v1],
    vv2 = Normalize[v2]
  },
  FillStainingKernel[{vv1, vv2, Max[0.0, #]& /@ (1 - (vv1^2 + vv2^2))}]
];
FillStainingKernel[m : {v1_?VectorQ, v2_?VectorQ, v3_?VectorQ}] := Module[
  {

  },
  Normalize /@ m
];

FillStainingKernel[stain : {_Dye..}] := Module[
  {
    n = Length[stain],
    dyes
  },
  If[Min[#.#& @@@ stain] == 0.0,
    Message[FillStainingKernel::sing];
    Return[$Failed];
  ];

  If[stain === {} || Length[stain] > 3,
    Message[FillStainingKernel::count];
    Return[$Failed]
  ];

  FillStainingKernel[Identity @@@ stain]
];

odC = Compile[{{pixel, _Real, 1}, {whitePoint, _Real, 1}, {blackPoint, _Real, 1}},
  With[
    {
      eps = 10.^-5
    },
    -Log[10.0, Max[#, eps] & /@ (pixel - blackPoint) / whitePoint]
  ],
  RuntimeAttributes -> {Listable},
  Parallelization -> True,
  CompilationTarget -> $compileTarget
];

compileKernel[kernel_?(MatrixQ[#, NumericQ]&)] := Compile[{{pixel, _Real, 1}},
  kernel.pixel,
  RuntimeAttributes -> {Listable},
  Parallelization -> True,
  CompilationTarget -> $compileTarget
];

calculateWhitePoint[data_] := Module[{pixel, dx, dy},
(* We don't use every pixel for the estimation. When image are large, we select ever dx, dy pixel *)
  {dy, dx} = Max[#, 1]& /@ Round[Log[100, Most@Dimensions[data]]];
  Median[Take[Reverse[SortBy[Flatten[data[[;; ;; dy, ;; ;; dx]], 1], Total], 10]]]
];

End[]; (* `Private` *)

EndPackage[];
