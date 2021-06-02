prev: {
  wolfram-engine = (prev.callPackage ./wolfram-engine { });
  mathematica-patched = (prev.callPackage ./mathematica { });
  wolfram-jupyter-kernel = (prev.callPackage ./wolfram-jupyter-kernel { });
}
