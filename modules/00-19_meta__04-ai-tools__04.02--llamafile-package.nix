# 04.02 Llamafile Package
# Llamafile overlay - ensures llamafile is available in pkgs
{ inputs, ... }:

{
  flake.overlays.llamafile = final: prev: {
    # Use llamafile from nixpkgs if available, otherwise build from source
    llamafile = if prev ? llamafile then prev.llamafile else
      prev.stdenv.mkDerivation {
        pname = "llamafile";
        version = "0.8.13";

        src = prev.fetchurl {
          url = "https://github.com/Mozilla-Ocho/llamafile/releases/download/0.8.13/llamafile-0.8.13";
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Placeholder
        };

        dontUnpack = true;

        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/llamafile
          chmod +x $out/bin/llamafile
        '';

        meta = with prev.lib; {
          description = "Distribute and run LLMs with a single file";
          homepage = "https://github.com/Mozilla-Ocho/llamafile";
          license = licenses.asl20;
          platforms = platforms.linux ++ platforms.darwin;
        };
      };

    # Python wrapper for constrained decoding using llama.cpp grammars
    llamafile-jdd = prev.writeScriptBin "llamafile-jdd" ''
      #!${prev.python3}/bin/python3
      """
      JDD Filename Generator with Constrained Decoding

      Uses llama.cpp's GBNF grammar to enforce self-describing filename patterns.
      Ensures LLM output strictly follows: XX-XX_category__XX-subcategory__XX.XX--description.nix

      This is for FILENAMES, not directories - all files are flat in modules/
      """
      import sys
      import subprocess
      import json
      import tempfile
      from pathlib import Path

      # GBNF grammar for JDD naming (llama.cpp format)
      JDD_GRAMMAR = '''
      root ::= range-start "-" range-end "_" category "__" subcat-num "-" subcategory "__" major "." minor "--" description ".nix"
      range-start ::= [0-9] [0-9]
      range-end ::= [0-9] [0-9]
      category ::= [a-z] [a-z-]*
      subcat-num ::= [0-9] [0-9]
      subcategory ::= [a-z] [a-z-]*
      major ::= [0-9] [0-9]
      minor ::= [0-9] [0-9]
      description ::= [a-z0-9] [a-z0-9-]*
      '''

      def run_with_grammar(model_path: str, prompt: str, use_grammar: bool = True):
          """Run llamafile with JDD grammar constraints"""

          args = [
              "${final.llamafile}/bin/llamafile",
              "-m", model_path,
              "-p", prompt,
              "--temp", "0.1",
              "-n", "150",
              "--no-display-prompt",
              "--silent-prompt",
              "-ngl", "9999",  # GPU acceleration
          ]

          # Add grammar constraint for structured output
          if use_grammar:
              with tempfile.NamedTemporaryFile(mode='w', suffix='.gbnf', delete=False) as f:
                  f.write(JDD_GRAMMAR)
                  grammar_file = f.name

              args.extend(["--grammar-file", grammar_file])

          try:
              result = subprocess.run(
                  args,
                  capture_output=True,
                  text=True,
                  timeout=60,
              )
              return result.stdout.strip()
          finally:
              if use_grammar and Path(grammar_file).exists():
                  Path(grammar_file).unlink()

      if __name__ == "__main__":
          if len(sys.argv) < 3:
              print("Usage: llamafile-jdd <model_path> <prompt> [--no-grammar]")
              sys.exit(1)

          model = sys.argv[1]
          prompt = sys.argv[2]
          use_grammar = "--no-grammar" not in sys.argv

          output = run_with_grammar(model, prompt, use_grammar)
          print(output)
    '';
  };

  # Apply overlay to system packages
  flake.nixosModules.llamafile-overlay = { config, lib, pkgs, ... }: {
    nixpkgs.overlays = [
      inputs.self.overlays.llamafile
    ];
  };
}
