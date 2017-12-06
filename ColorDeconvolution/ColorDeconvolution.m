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
Staining::usage = "Staining[name] a set of predefined stainings";
Dye::usage = "Dye[{r,g,b}] defines the (subtractive) color value for one specific dye. This can included in a Staining, \
which consists of 1-3 dyes.";

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

ColorDeconvolution[img_Image, stain : {_Dye..} | _CompiledFunction, opts : OptionsPattern[]] := Module[
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
  If[Head[stain] === List,
    kernel = CreateStainingKernel[stain];
    If[kernel =!= $Failed,
      kernel = compileKernel[kernel];
    ],
  (* else, stain is already a compiled kernel *)
    kernel = stain
  ];
  data = iColorDeconvolution[data, kernel];
  Image /@ Transpose[data, {2, 3, 1}]
];

iColorDeconvolution[data_?(TensorQ[#, NumericQ]&), kernel_CompiledFunction] := Module[
  {
    odData,
    whitePoint,
    c
  },
  whitePoint = calculateWhitePoint[data];
  odData = odC[data, whitePoint];
  kernel[odData]
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
CreateStainingKernel[{v1_?VectorQ, v2_?VectorQ}] := With[
  {
    vv1 = Normalize[v1],
    vv2 = Normalize[v2]
  },
  CreateStainingKernel[{vv1, vv2, Max[0.0, #]& /@ (1 - (vv1^2 + vv2^2))}]
];
CreateStainingKernel[m : {v1_?VectorQ, v2_?VectorQ, v3_?VectorQ}] := Module[
  {

  },
  Inverse[
    Normalize /@ m
  ]
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

compileKernel[kernel_?(MatrixQ[#, NumericQ]&)] := Compile[{{pixel, _Real, 1}},
  kernel.pixel,
  RuntimeAttributes -> {Listable},
  Parallelization -> True,
  CompilationTarget -> $compileTarget
];

calculateWhitePoint[data_] := Module[{pixel, dx, dy},
(* We don't use every pixel for the estimation. When image are large, we select ever dx, dy pixel *)
  {dy, dx} = Max[#, 1]& /@ Round[Log[100, Most@Dimensions[data]]];
  Median[Take[Reverse[SortBy[Flatten[data[[;; ;; dy, ;; ;; dx]], 1], Total], 100]]]
];

End[]; (* `Private` *)

EndPackage[];
