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
FillStainingKernel::usage = "FillStainingKernel[Staining[..]] or FillStainingKernel[{_Dye, ..}]";
Staining::usage = "Staining[name] a set of predefined stainings";
Dye::usage = "Dye[{r,g,b}] defines the (subtractive) color value for one specific dye. This can included in a Staining, \
which consists of 1-3 dyes.";
VisualiseStaining::usage = "VisualiseStaining[stain] or VisualiseStaining[precompKernel] shows the colors used in the staining.";
CompileStainingKernel::usage = "CompileStainingKernel[staining] creates a pre-compiled version of a staining kernel that can \
be used in several runs without re-compiling.";
PrecompiledKernel::usage = "Is a precompiled staining kernel.";
ColorDeconvolutionResult::usage = "Result that holds all information about a ColorDeconvolution.";

BrightField::usage = "BrightField is an option for ColorDeconvolution. Defines the white point/image. Can be Automatic, and {r,g,b} triple or an image of the same size.";
DarkField::usage = "DarkField currently not used.";
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

$stainingNames = {
  "H&E",
  "H&E 2",
  "H DAB",
  "Feulgen Light Green",
  "Giemsa",
  "FastRed FastBlue DAB",
  "Methyl Green DAB",
  "H&E DAB",
  "H AEC",
  "Azan-Mallory",
  "Masson Trichrome",
  "Alcian Blue & H",
  "H PAS",
  "Brilliant Blue",
  "RGB",
  "CMY"
};

$dyeNames = {
  "Hematoxylin",
  "Hematoxylin2",
  "Eosin",
  "Eosin2",
  "Alcian Blue",
  "DAB",
  "PAS",
  "Fast Red"
};

addCompletions[arg_] := FE`Evaluate[FEPrivate`AddSpecialArgCompletion[arg]];

addCompletions["Dye" -> {$dyeNames}];
addCompletions["Staining" -> {$stainingNames}];

Options[ColorDeconvolution] = {
  BrightField -> Automatic,
  DarkField -> Missing
};
ColorDeconvolution[img_Image, stain : {_Dye..}, opts : OptionsPattern[]] := Module[
  {
    kernel = CompileStainingKernel[stain]
  },
  ColorDeconvolution[img, kernel, opts] /; Head[kernel] === PrecompiledKernel
];
ColorDeconvolution[img_Image, kernel_PrecompiledKernel, opts : OptionsPattern[]] := Module[
  {
    data,
    whitePoint,
    odData
  },
  If[ImageChannels[img] =!= 3 && ImageColorSpace[img] =!= "RGB",
    Message[ColorDeconvolution::wimg];
    Return[$Failed]
  ];
  data = ImageData[img, "Real", Interleaving -> True];
  If[OptionValue[BrightField] === Automatic,
    whitePoint = calculateWhitePoint[data],
    whitePoint = OptionValue[BrightField]
  ];
  odData = odC[data, whitePoint];
  data = kernel[[1]][odData];
  ColorDeconvolutionResult[Transpose[Clip[data, {0, 1}], {2, 3, 1}], odData, kernel]
];

Format[ColorDeconvolutionResult[_, _, kernel_]] := With[
  {
    gr = VisualiseStaining[kernel]
  },
  ColorDeconvolutionResult[Graphics[First[gr], ImageSize -> Tiny]]
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

odC = Compile[{{pixel, _Real, 1}, {i0, _Real, 1}},
  With[
    {
      eps = 10.^-5
    },
    -Log[10.0, Max[#, eps] & /@ pixel / i0]
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
  Median[Take[Reverse[SortBy[Flatten[data, 1], Total], 10]]]
];

End[]; (* `Private` *)

EndPackage[];
