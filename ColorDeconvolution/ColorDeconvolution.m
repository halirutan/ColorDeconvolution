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

ColorDeconvolution::usage = "ColorDeconvolution[img, Staining[\"stain-name\"]] creates a color deconvolution regarding the colors" <>
    "given in the staining.";
CreateStainingKernel::usage = "CreateStainingKernel[Staining[..]] or CreateStainingKernel[{_Dye, ..}]";
CompileStainingKernel::usage = "CompileStainingKernel[staining | { _Dye..}] creates a pre-compiled staining kernel that can be used in " <>
    "in successive runs of ColorDeconvolution. ";
ColorDeconvolutionKernel::usage = "ColorDeconvolutionKernel is an object returned by CompileStainingKernel and can be used for repeated calls to ColorDeconvolution.";
BrightField::usage = "BrightField is an option for ColorDeconvolution. " <>
    "It is used to equalize the brightness and remove incoherent lighting." <>
    "Can be None, Automatic or an Image with the same specification as the input image. " <>
    "Setting None will effectively use a white point of 1. Automatic will try to calculate the brightest point from the image by " <>
    "taking a small sample of pixels. Supplying an Image that was taken with the same Microscope settings works best.";
DarkField::usage = "DarkField is an option for ColorDeconvolution. " <>
    "It is used to remove camera pixel defects and should be acquired with the camera light-path closed on the microscope." <>
    "Can be None or an Image with the same specifications as the input image. ";
ClipData::usage = "ClipData is an option for ColorDeconvolution. If set to True, the deconvolution result is clipped to the range of [0,1].";
ColorDeconvolutionResult::usage = "ColorDeconvolutionResult[...] is an object that contains the result from a ColorDeconvolution.";
Staining::usage = "Staining[name] a set of predefined stainings";
Dye::usage = "Dye[{r,g,b}] defines the (subtractive) color value for one specific dye. This can included in a Staining, which consists of 1-3 dyes.";
ColorDeconvolutionKernelizer::usage = "ColorDeconvolutionKernelizer[img, precompiledKernel, opts] creates a dynamic view for adjusting dye colors.";



Begin["`Private`"];

(* Set compilation target depending on whether we find a working C compiler *)
$compileTarget = "C";
Quiet[
  Check[
    Compile[{}, 1, CompilationTarget -> $compileTarget],
    $compileTarget = "MVM"
  ]
];

(* ::Section:: *)
(* Common color vectors for specific dyes and stainings *)

(* ::Text:: *)
(* *)

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

Staining["AlcianBlue & H Luisa"] = {Dye[{0.7622531066123409`, 0.6472667159256441`, 0.003999989333341867`}], Dye[{0.4066847930872072`, 0.8110391089785727`, 0.4205033207703107`}], Dye[{0.45181280070179025`, 0.`, 0.8921127692853659`}]};


(* Adding completion for the built-in dye- and staining-names *)
$stainingNames = Keys[DownValues[Staining]][[All, 1, 1]];
$dyeNames = Keys[DownValues[Dye]][[All, 1, 1]];
addCompletions[arg_] := FE`Evaluate[FEPrivate`AddSpecialArgCompletion[arg]];
addCompletions["Dye" -> {$dyeNames}];
addCompletions["Staining" -> {$stainingNames}];

(* Nice rendering of precompiled kernel *)
ColorDeconvolutionResult /:
    MakeBoxes[cd : ColorDeconvolutionResult[data_, kernel_], form : (StandardForm | TraditionalForm)] :=
    BoxForm`ArrangeSummaryBox[
      ColorDeconvolutionResult,
      Null,
      ColorDeconvolution`Private`VisualiseStaining[kernel],
      {
        BoxForm`SummaryItem[{"Image Dimension: ", Reverse@Dimensions[First[data]]}]
      },
      {},
      form
    ];

ColorDeconvolutionResult[data_List, _][n_ /; 1 <= n <= 3] := Image[data[[n]], "Real"];
ColorDeconvolutionResult[data_List, ColorDeconvolutionKernel[_, colors_List]][n_ /; 1 <= n <= 3, Colorize] := colorizeStaining[data[[n]], colors[[n]]];
ColorDeconvolutionResult[_List, kernel_]["Kernel"] := kernel;

validImageQ[img_Image] := ImageChannels[img] === 3 && ImageColorSpace[img] === "RGB";
validImageQ[___] := False;

Options[ColorDeconvolution] = {
  BrightField -> None,
  DarkField -> None,
  ClipData -> True
};

ColorDeconvolution::wimg = "The `` must have 3 channels and in RGB color-space.";
ColorDeconvolution::wimgRef = "The `` must have 3 channels and in RGB color-space and be of the same size than the input image.";
ColorDeconvolution::wstain = "The staining must consist of exactly 3 dyes";
ColorDeconvolution[img_Image, stain : {_Dye..}, opts : OptionsPattern[]] := Module[{},
  If[stain === {} || Length[stain] > 3,
    Message[ColorDeconvolution::wstain];
    Return[$Failed]
  ];
  ColorDeconvolution[img, CompileStainingKernel[stain], opts]
];

ColorDeconvolution[img_Image, kernel_ColorDeconvolutionKernel, opts : OptionsPattern[]] := Module[
  {
    data, whiteImage, blackImage, brightField, darkField, invKernel = First[kernel], odData
  },
  If[Not[validImageQ[img]],
    Message[ColorDeconvolution::wimg, "input image"];
    Return[$Failed]
  ];

  whiteImage = OptionValue[BrightField];
  If[(whiteImage =!= Automatic && whiteImage =!= None) && !validImageQ[whiteImage] && ImageDimensions[img] =!= ImageDimensions[whiteImage],
    Message[ColorDeconvolution::wimgRef, "White Image"];
    whiteImage = None;
  ];

  blackImage = OptionValue[DarkField];
  If[blackImage =!= None && !validImageQ[blackImage] && ImageDimensions[img] =!= ImageDimensions[blackImage],
    Message[ColorDeconvolution::wimgRef, "White Image"];
    blackImage = None
  ];

  data = ImageData[img, "Real", Interleaving -> True];

  Switch[
    whiteImage,
    _Image,
    brightField = ImageData[whiteImage, "Real", Interleaving -> True],
    Automatic,
    brightField = calculateWhitePoint[data],
    None,
    brightField = {1.0, 1.0, 1.0}
  ];

  Switch[
    blackImage,
    _Image,
    darkField = ImageData[blackImage, "Real", Interleaving -> True],
    None,
    darkField = {0.0, 0.0, 0.0}
  ];
  odData = odC[data, brightField, darkField];
  data = Transpose[ArrayReshape[Flatten[odData, 1].invKernel, Dimensions[odData]], {2, 3, 1}];
  If[TrueQ[OptionValue[ClipData]],
    data = Clip[data, {0, 1}];
  ];
  ColorDeconvolutionResult[data, kernel]
];

CompileStainingKernel[stain : {_Dye..}] := Module[
  {
    kernel = CreateStainingKernel[stain],
    invKernel,
    result = $Failed
  },
  If[MatrixQ[kernel, NumericQ],
    invKernel = Inverse[kernel];
    If[MatrixQ[invKernel, NumericQ],
      result = ColorDeconvolutionKernel[invKernel, Dye /@ kernel]
    ]
  ];
  result
];

VisualiseStaining[ColorDeconvolutionKernel[_, stain_]] := VisualiseStaining[stain];
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

(* Nice rendering of precompiled kernel *)
ColorDeconvolutionKernel /:
    MakeBoxes[kernel : ColorDeconvolutionKernel[invKernel_, dyes_], form : (StandardForm | TraditionalForm)] :=
    BoxForm`ArrangeSummaryBox[
      ColorDeconvolutionKernel,
      kernel,
      ColorDeconvolution`Private`VisualiseStaining[kernel],
      {
        BoxForm`SummaryItem[{"Colors: ", Length[dyes]}]
      },
      {
        MatrixForm[Identity@@@dyes]
      }
      ,
      form
    ];

CreateStainingKernel::sing = "At least one Dye as only zero entries.";
CreateStainingKernel::count = "1-3 colors need to be specified.";
CreateStainingKernel[stain : {_Dye}] := CreateStainingKernel[Identity @@@ stain];
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



odC = Compile[{{pixel, _Real, 1}, {brightField, _Real, 1}, {darkField, _Real, 1}},
  With[
    {
      eps = 10.^-5
    },
    -Log[10.0, Max[#, eps] & /@ (pixel - darkField) / ( brightField - darkField)]
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

(* ::Section:: *)
(* Dynamic Functions *)

toRGBTriple[{phi_, theta_}] := {Cos[phi] Cos[theta], Cos[theta] Sin[phi], Sin[theta]};
toRGBTripleInv[{phi_, theta_}] := 1 - toRGBTriple[{phi, theta}];
fromRGBTriple[{r_, g_, b_}] := {ArcTan[r, g], Pi / 2 - ArcTan[b, Sqrt[g^2 + r^2]]};

With[
  {
    backGr = RegionPlot[ 0 <= x <= Pi / 2 && 0 <= y <= Pi / 2, {x, 0, Pi / 2}, {y, 0, Pi / 2},
      ColorFunction -> Function[{phi, theta}, RGBColor @@ toRGBTripleInv[{phi, theta}]],
      ColorFunctionScaling -> False,
      Frame -> False,
      ImageSize -> 512,
      PlotRangePadding -> None, ImagePadding -> None]
  },
  ColorDeconvolutionKernelizer[img_, ColorDeconvolutionKernel[ kernel_, dyes : {Dye[v1_], Dye[v2_], Dye[v3_]}], opts___] := DynamicModule[
    {
      p1, p2, p3, colorBox, img1, img2, img3, update, kernelC, showImg,
      cdResult, statistic
    },
    colorBox[p_] := Graphics[{RGBColor @@ toRGBTripleInv[p], Rectangle[]}, ImageSize -> 500/3];
    update[] :=
        (
          kernelC = CompileStainingKernel[Dye[toRGBTriple[#]] & /@ {p1, p2, p3}];
          cdResult = ColorDeconvolution[img, kernelC, opts];
          img1 = cdResult[1];
          img2 = cdResult[2];
          img3 = cdResult[3];
        );
    showImg[i_Image] := Show[i,ImageSize->256];
    showImg[__] := Graphics[{}, Frame -> True, ImageSize -> ImageDimensions[img], Axes -> False, FrameTicks -> None];
    statistic[i_Integer] := If[Head[cdResult] === ColorDeconvolutionResult,
      With[
        {
          d = 255 * Flatten[cdResult[[1, i]]]
        },
        Row[Round[#, .001]& /@ {Min[d], Max[d], Mean[d]}, Spacer[15]]
      ], "Unknown"
    ];
    {p1, p2, p3} = fromRGBTriple /@ (CreateStainingKernel[dyes]);
    update[];
    Deploy@Panel@Grid[{
      {
        LocatorPane[Dynamic[{p1, p2, p3}, {Automatic, Automatic, update[] &}], backGr, {{0, 0}, {Pi / 2, Pi / 2}}, Appearance -> {"(1)", "(2)", "(3)"}],
        Grid[{{Show[img, ImageSize -> 256], Dynamic@showImg[img1]}, {Dynamic@showImg[img2], Dynamic@showImg[img3]}}]
      },
      {
        Grid[{{Dynamic[colorBox[p1]], Dynamic[colorBox[p2]], Dynamic[colorBox[p3]]}}],
        Grid[
          {
            {"Min/Max/Mean Value Vector 1:", Dynamic@statistic[1]},
            {"Min/Max/Mean Value Vector 2:", Dynamic@statistic[2]},
            {"Min/Max/Mean Value Vector 3:", Dynamic@statistic[3]},
            {Button["Copy Kernel", CopyToClipboard[kernelC[[-1]]]]}
          }, Frame -> All
        ]
      }
    }, Frame -> All
    ]
  ];
];


End[]; (* `Private` *)

EndPackage[];
