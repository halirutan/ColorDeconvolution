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

CreateStainingKernel::usage = "CreateStainingKernel[Staining[..]] or CreateStainingKernel[{_Dye, ..}]";
Staining::usage = "Staining[name] a set of predefined stainings";

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


Staining["H&E"] = {Dye[{0.644211, 0.716556, 0.266844}], Dye[{0.092789, 0.954111, 0.283111}], Dye[{0., 0., 0.}]};
Staining["H&E 2"] = {Dye[{0.490157, 0.768971, 0.410402}], Dye[{0.0461534, 0.842068, 0.537393}], Dye[{0., 0., 0.}]};
Staining["H DAB"] = {Dye[{0.65, 0.704, 0.286}], Dye[{0.268, 0.57, 0.776}], Dye[{0., 0., 0.}]};
Staining["Feulgen Light Green"] = {Dye[{0.464209, 0.830083, 0.308272}], Dye[{0.947055, 0.253738, 0.196508}], Dye[{0., 0., 0.}]};
Staining["Giemsa"] = {Dye[{0.83475, 0.513556, 0.19633}], Dye[{0.092789, 0.954111, 0.283111}], Dye[{0., 0., 0.}]};
Staining["FastRed FastBlue DAB"] = {Dye[{0.213939, 0.851127, 0.47794}], Dye[{0.748903, 0.606242, 0.267311}], Dye[{0.268, 0.57, 0.776}]};
Staining["Methyl Green DAB"] = {Dye[{0.98, 0.144316, 0.133146}], Dye[{0.268, 0.57, 0.776}], Dye[{0., 0., 0.}]};
Staining["H&E DAB"] = {Dye[{0.65, 0.704, 0.286}], Dye[{0.072, 0.99, 0.105}], Dye[{0.268, 0.57, 0.776}]};
Staining["H AEC"] = {Dye[{0.65, 0.704, 0.286}], Dye[{0.2743, 0.6796, 0.6803}], Dye[{0., 0., 0.}]};
Staining["Azan-Mallory"] = {Dye[{0.853033, 0.508733, 0.112656}], Dye[{0.0928988, 0.866201, 0.490985}], Dye[{0.107328, 0.367654, 0.923748}]};
Staining["Masson Trichrome"] = {Dye[{0.799511, 0.591352, 0.105287}], Dye[{0.0999716, 0.737386, 0.668033}], Dye[{0., 0., 0.}]};
Staining["Alcian Blue & H"] = {Dye[{0.874622, 0.457711, 0.158256}], Dye[{0.552556, 0.7544, 0.353744}], Dye[{0., 0., 0.}]};
Staining["H PAS"] = {Dye[{0.644211, 0.716556, 0.266844}], Dye[{0.175411, 0.972178, 0.154589}], Dye[{0., 0., 0.}]};
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

ColorDeconvolution::wimg = "Wrong image format. ColorDeconvolution requires a 3 channel RGB images.";
ColorDeconvolution::wstain = "1-3 dyes that define the stained are required.";
ColorDeconvolution[img_Image, stain : {_Dye..}, opts : OptionsPattern[]] := Module[
  {
    data, kernel
  },
  If[ImageChannels[img] =!= 3 && ImageColorSpace[img] =!= "RGB",
    Message[ColorDeconvolution::wimg];
    Return[$Failed]
  ];
  If[stain === {} || Length[stain] > 3,
    Message[ColorDeconvolution::wstain];
    Return[$Failed]
  ];
  data = ImageData[img, "Real", Interleaving -> True];
  kernel = CreateStainingKernel[stain];
  If[kernel =!= $Failed,
    Return[iColorDeconvolution[data, kernel, opts]]
  ];
  $Failed
];

iColorDeconvolution[data_, kernel_] := Module[
  {
    odData,
    whitePoint
  },
  whitePoint = calculateWhitePoint[data];
  odData = odC[data, whitePoint];


];

CreateStainingKernel::sing = "At least one Dye as only zero entries.";
CreateStainingKernel::count = "1-3 colors need to be specified.";
CreateStainingKernel[stain : {Dye_}] := CreateStainingKernel[Identity @@@ stain];
CreateStainingKernel[{vec_?VectorQ}] := With[
  {
    v = Normalize[vec]
  },
  CreateStainingKernel[{v, RotateLeft[v]}] /; Norm[v] != 0.0
];
CreateStainingKernel[{v1_?VectorQ, v2_VectorQ}] := With[
  {
    vv1 = Normalize[v1],
    vv2 = Normalize[v2]
  },
  CreateStainingKernel[{vv1, vv2, Min[0.0, #]& /@ (1 - (vv1^2 + vv2^2))}]
];
CreateStainingKernel[m : {v1_?VectorQ, v2_?VectorQ, v3_?VectorQ}] := Module[
  {

  },
  Normalize /@ m
];

CreateStainingKernel[stain : {_Dye..}] := Module[
  {
    n = Length[stain],
    dyes
  },
  If[Min[#.#& @@@ stain] == 0.0,
    Message[CreateStainingKernel::sing];
    Return[$Failed];
  ];

  If[stain === {} || Length[stain] > 3,
    Message[CreateStainingKernel::count];
    Return[$Failed]
  ];

  CreateStainingKernel[Identity @@@ stain]
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

applyKernelC = Compile[{{pixel, _Real, 1}, {kernel, _Real, 2}},
  kernel.pixel,
  RuntimeAttributes -> {Listable},
  Parallelization -> True,
  CompilationTarget -> $compileTarget
];

calculateWhitePoint[data_] := Module[{pixel, dx, dy},
(* We don't use every pixel for the estimation. When image are large, we select ever dx, dy pixel *)
  {dy, dx} = Max[#, 1]& /@ Round[Log[100, Dimensions[data]]];
  Median[Take[Reverse[SortBy[data[[;; dy, ;; dx]], Total], 100]]]
];

End[]; (* `Private` *)

EndPackage[];
