(* ::Package:: *)

(* ::Title:: *)
(*ReggeWheeler package*)


(* ::Section::Closed:: *)
(*Create Package*)


BeginPackage["ReggeWheeler`ReggeWheelerRadial`",
  {
    "ReggeWheeler`NumericalIntegration`",
    "ReggeWheeler`MST`RenormalizedAngularMomentum`",
    "ReggeWheeler`MST`MST`",
    "SpinWeightedSpheroidalHarmonics`",
    "DifferentialEquations`InterpolatingFunctionAnatomy`"
  }];


(* Usage messages *)
ReggeWheelerRadial::usage = "ReggeWheelerRadial[s, l, \[Omega]] computes homogeneous solutions to the Regge Wheeler equation."
ReggeWheelerRadialFunction::usage = "ReggeWheelerRadialFunction[s, l, \[Omega], assoc] is an object representing a homogeneous solution to the Regge Wheeler equation."


(* Error messages *)
ReggeWheelerRadial::optx = "Unknown options in `1`";
ReggeWheelerRadial::dm = "Option `1` is not valid with BoundaryConditions \[RightArrow] `2`.";
ReggeWheelerRadialFunction::dmval = "Radius `1` lies outside the computational domain. Results may be incorrect.";


Begin["`Private`"];


(* ::Section::Closed:: *)
(*ReggeWheelerRadial*)


(* ::Subsection::Closed:: *)
(*Numerical Integration Method*)


Options[ReggeWheelerRadialNumericalIntegration] = {
  "Domain" -> None};


domainQ[domain_] := MatchQ[domain, {_?NumericQ, _?NumericQ} | (_?NumericQ) | All];


ReggeWheelerRadialNumericalIntegration[s_Integer, l_Integer, \[Omega]_, BCs_, opts:OptionsPattern[]] :=
 Module[{\[Lambda], RWRF, norms, solFuncs, domains, m = 0, a=0},
  (* Compute the eigenvalue *)
  \[Lambda] = SpinWeightedSpheroidalEigenvalue[s, l, m, a \[Omega]];

  (* Function to construct a single ReggeWheelerRadialFunction *)
  RWRF[bc_, ns_, sf_, domain_] :=
   Module[{solutionFunction},
    solutionFunction = sf[domain];
    ReggeWheelerRadialFunction[s, l, \[Omega],
     Association["s" -> s, "l" -> l, "\[Omega]" -> \[Omega], "Eigenvalue" -> \[Lambda],
      "Method" -> {"NumericalIntegration"},
      "BoundaryConditions" -> bc, "Amplitudes" -> ns,
      "Domain" -> If[domain === All, {2, \[Infinity]}, First[InterpolatingFunctionDomain[solutionFunction]]],
      "RadialFunction" -> solutionFunction
     ]
    ]
   ];

  (* Domain over which the numerical solution can be evaluated *)
  domains = OptionValue["Domain"];
  If[ListQ[BCs],
    If[!MatchQ[domains, (List|Association)[Rule["In"|"Up",_?domainQ]..]],
      Message[ReggeWheelerRadial::dm, "Domain" -> domains, BCs];
      Return[$Failed];
    ];
    domains = Lookup[domains, BCs, None]; 
    If[!AllTrue[domains, domainQ],
      Message[ReggeWheelerRadial::dm, "Domain" -> OptionValue["Domain"], BCs];
      Return[$Failed];
    ];
  ,
    If[!domainQ[domains],
      Message[ReggeWheelerRadial::dm, "Domain" -> domains, BCs];
      Return[$Failed];
    ];
  ];

  (* Asymptotic normalizations such that we have unit transmission coefficient *)
  norms = <|"In" -> <|"Transmission" -> 1|>, "Up" -> <|"Transmission" -> 1|>|>;
  norms = Lookup[norms, BCs];

  (* Solution functions for the specified boundary conditions *)
  solFuncs =
   <|"In" :> ReggeWheeler`NumericalIntegration`Private`Psi[s, l, \[Omega], "In"],
     "Up" :> ReggeWheeler`NumericalIntegration`Private`Psi[s, l, \[Omega], "Up"]|>;
  solFuncs = Lookup[solFuncs, BCs];

  If[ListQ[BCs],
    Return[Association[MapThread[#1 -> RWRF[#1, #2, #3, #4]&, {BCs, norms, solFuncs, domains}]]],
    Return[RWRF[BCs, norms, solFuncs, domains]]
  ];
];


(* ::Subsection::Closed:: *)
(*MST Method*)


Options[ReggeWheelerRadialMST] = {
  "RenormalizedAngularMomentum" -> "Monodromy"};


ReggeWheelerRadialMST[s_Integer, l_Integer, \[Omega]_, BCs_, opts:OptionsPattern[]] :=
 Module[{\[Lambda], \[Nu], norms, solFuncs, RWRF, m = 0, a=0},
  (* Compute the eigenvalue and renormalized angular momentum *)
  \[Lambda] = SpinWeightedSpheroidalEigenvalue[s, l, m, a \[Omega]];
  \[Nu] = RenormalizedAngularMomentum[s, l, m, a, \[Omega], \[Lambda], Method -> OptionValue["RenormalizedAngularMomentum"]];

  (* Function to construct a ReggeWheelerRadialFunction *)
  RWRF[bc_, ns_, sf_] :=
    ReggeWheelerRadialFunction[s, l, \[Omega],
     Association["s" -> s, "l" -> l, "\[Omega]" -> \[Omega], "Eigenvalue" -> \[Lambda],
      "Method" -> {"MST", "RenormalizedAngularMomentum" -> \[Nu]},
      "BoundaryConditions" -> bc, "Amplitudes" -> ns,
      "Domain" -> {2, \[Infinity]}, "RadialFunction" -> sf
     ]
    ];

  (* Compute the asymptotic normalisations *)
  norms = ReggeWheeler`MST`MST`Private`Amplitudes[s, l, m, a, 2\[Omega], \[Nu], \[Lambda]];

  (* Solution functions for the specified boundary conditions *)
  solFuncs =
    <|"In" :> ReggeWheeler`MST`MST`Private`MSTRadialIn[s,l,m,a,2\[Omega],\[Nu],\[Lambda],norms["In"]["Transmission"]],
      "Up" :> ReggeWheeler`MST`MST`Private`MSTRadialUp[s,l,m,a,2\[Omega],\[Nu],\[Lambda],norms["Up"]["Transmission"]]|>;
  solFuncs = Lookup[solFuncs, BCs];

  (* Select normalisation coefficients for the specified boundary conditions and rescale
     to give unit transmission coefficient. *)
  norms = norms/norms[[All, "Transmission"]];
  norms = Lookup[norms, BCs];

  If[ListQ[BCs],
    Return[Association[MapThread[#1 -> RWRF[#1, #2, #3]&, {BCs, norms, solFuncs}]]],
    Return[RWRF[BCs, norms, solFuncs]]
  ];
];


(* ::Subsection::Closed:: *)
(*ReggeWheelerRadial*)


SyntaxInformation[ReggeWheelerRadial] =
 {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};


Options[ReggeWheelerRadial] = {
  Method -> "MST",
  "BoundaryConditions" -> {"In", "Up"}
};


ReggeWheelerRadial[s_Integer, l_Integer, \[Omega]_?InexactNumberQ, opts:OptionsPattern[]] :=
 Module[{RWRF, subopts, BCs},
  (* Extract suboptions from Method to be passed on. *)
  If[ListQ[OptionValue[Method]],
    subopts = Rest[OptionValue[Method]];,
    subopts = {};
  ];

  (* Determine which boundary conditions the homogeneous solution(s) should satisfy *)
  BCs = OptionValue["BoundaryConditions"];
  If[!MatchQ[BCs, "In"|"Up"|{("In"|"Up")..}], 
    Message[ReggeWheelerRadial::optx, "BoundaryConditions" -> BCs];
    Return[$Failed];
  ];

  (* Decide which implementation to use *)
  Switch[OptionValue[Method],
    "MST" | {"MST", OptionsPattern[ReggeWheelerRadialMST]},
      RWRF = ReggeWheelerRadialMST,
    "NumericalIntegration" | {"NumericalIntegration", OptionsPattern[ReggeWheelerRadialNumericalIntegration]},
      RWRF = ReggeWheelerRadialNumericalIntegration;,
    _,
      Message[ReggeWheelerRadial::optx, Method -> OptionValue[Method]];
      Return[$Failed];
  ];

  (* Check only supported sub-options have been specified *)  
  If[subopts =!= (subopts = FilterRules[subopts, Options[RWRF]]),
    Message[ReggeWheelerRadial::optx, Method -> OptionValue[Method]];
  ];

  (* Call the chosen implementation *)
  RWRF[s, l, \[Omega], BCs, Sequence@@subopts]
];


(* ::Section::Closed:: *)
(*ReggeWheelerRadialFunction*)


SetAttributes[ReggeWheelerRadialFunction, {NumericFunction}];

Format[ReggeWheelerRadialFunction[s_, l_, \[Omega]_, assoc_]] := 
  "ReggeWheelerRadialFunction["<>ToString[s]<>","<>ToString[l]<>","<>ToString[\[Omega]]<>",<<>>]";

ReggeWheelerRadialFunction[s_, l_, \[Omega]_, assoc_][y_String] /; !MemberQ[{"RadialFunction"}, y] :=
  assoc[y];


outsideDomainQ[r_, rmin_, rmax_] := Min[r]<rmin || Max[r]>rmax;


ReggeWheelerRadialFunction[s_, l_, \[Omega]_, assoc_][r:(_?NumericQ|{_?NumericQ..})] :=
 Module[{rmin, rmax},
  {rmin, rmax} = assoc["Domain"];
  If[outsideDomainQ[r, rmin, rmax],
    Message[ReggeWheelerRadialFunction::dmval, #]& /@ Select[Flatten[{r}], outsideDomainQ[#, rmin, rmax]&];
  ];
  Quiet[assoc["RadialFunction"][r], InterpolatingFunction::dmval]
 ];


Derivative[n_][ReggeWheelerRadialFunction[s_, l_, \[Omega]_, assoc_]][r:(_?NumericQ|{_?NumericQ..})] :=
 Module[{rmin, rmax},
  {rmin, rmax} = assoc["Domain"];
  If[outsideDomainQ[r, rmin, rmax],
    Message[ReggeWheelerRadialFunction::dmval, #]& /@ Select[Flatten[{r}], outsideDomainQ[#, rmin, rmax]&];
  ];
  Quiet[Derivative[n][assoc["RadialFunction"]][r], InterpolatingFunction::dmval]
 ];


(* ::Section::Closed:: *)
(*End Package*)


End[]
EndPackage[];
