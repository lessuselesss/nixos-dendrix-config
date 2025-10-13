#!/usr/bin/env -S deno run --allow-read

/**
 * Flake-Parts Module Structure Validator
 * 
 * This script validates that all .nix files in the modules/ directory
 * follow the flake-parts pattern and proper function signatures.
 */

import { walk } from "@std/fs/walk";
import { extname, relative } from "@std/path";
import { red, green, yellow, bold } from "@std/fmt/colors";

interface ValidationError {
  file: string;
  line: number;
  error: string;
  severity: "error" | "warning";
}

interface ValidationResult {
  totalFiles: number;
  validFiles: number;
  errors: ValidationError[];
}

/**
 * Check if a module follows the flake-parts pattern
 */
function validateModuleContent(content: string, filePath: string): ValidationError[] {
  const errors: ValidationError[] = [];
  const lines = content.split('\n');
  
  // Check for proper function signature: { inputs, ... }:
  const functionSignatureRegex = /^\s*\{\s*inputs\s*,\s*\.\.\.\s*\}\s*:\s*$/;
  let hasFunctionSignature = false;
  let functionSignatureLine = 0;
  
  // Check for flake-parts patterns
  const flakeModuleRegex = /flake\.nixosModules\.\w+\s*=/;
  const flakeConfigRegex = /flake\.nixosConfigurations\.\w+\s*=/;
  let hasFlakePattern = false;
  let flakePatternLine = 0;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNumber = i + 1;
    
    // Skip comments and empty lines for signature check
    if (line.trim().startsWith('#') || line.trim() === '') {
      continue;
    }
    
    // Check for function signature
    if (functionSignatureRegex.test(line)) {
      hasFunctionSignature = true;
      functionSignatureLine = lineNumber;
    }
    
    // Check for flake-parts patterns
    if (flakeModuleRegex.test(line) || flakeConfigRegex.test(line)) {
      hasFlakePattern = true;
      flakePatternLine = lineNumber;
    }
  }
  
  // Validate function signature
  if (!hasFunctionSignature) {
    errors.push({
      file: filePath,
      line: 1,
      error: "Missing proper function signature '{ inputs, ... }:' - flake-parts modules must start with this signature",
      severity: "error"
    });
  }
  
  // Check for flake-parts pattern (allow some flexibility)
  const hasFlakeReference = content.includes('flake.') || 
                           content.includes('inputs.self.nixosModules') ||
                           content.includes('inputs.self.nixosConfigurations');
  
  if (!hasFlakeReference) {
    errors.push({
      file: filePath,
      line: 1,
      error: "Module doesn't appear to follow flake-parts pattern - should define flake outputs or reference flake modules",
      severity: "warning"
    });
  }
  
  // Additional checks
  if (content.includes('import ') && !content.includes('inputs.')) {
    const importLines = lines
      .map((line, index) => ({ line, number: index + 1 }))
      .filter(({ line }) => line.includes('import ') && !line.trim().startsWith('#'));
    
    importLines.forEach(({ line, number }) => {
      errors.push({
        file: filePath,
        line: number,
        error: "Direct imports detected - flake-parts modules should use inputs instead of direct imports",
        severity: "warning"
      });
    });
  }
  
  return errors;
}

/**
 * Validate all .nix files in the modules directory
 */
async function validateModules(modulesPath: string): Promise<ValidationResult> {
  const result: ValidationResult = {
    totalFiles: 0,
    validFiles: 0,
    errors: []
  };
  
  try {
    for await (const entry of walk(modulesPath)) {
      if (entry.isFile && extname(entry.path) === '.nix') {
        result.totalFiles++;
        
        try {
          const content = await Deno.readTextFile(entry.path);
          const relativePath = relative(modulesPath, entry.path);
          const errors = validateModuleContent(content, relativePath);
          
          if (errors.length === 0) {
            result.validFiles++;
          } else {
            result.errors.push(...errors);
          }
          
        } catch (error) {
          result.errors.push({
            file: relative(modulesPath, entry.path),
            line: 1,
            error: `Failed to read file: ${error.message}`,
            severity: "error"
          });
        }
      }
    }
  } catch (error) {
    console.error(red(`Error walking modules directory: ${error.message}`));
    Deno.exit(1);
  }
  
  return result;
}

/**
 * Print validation results
 */
function printResults(result: ValidationResult) {
  console.log(bold("Flake-Parts Module Validation Results"));
  console.log("═".repeat(50));
  
  const errorCount = result.errors.filter(e => e.severity === "error").length;
  const warningCount = result.errors.filter(e => e.severity === "warning").length;
  
  console.log(`Files scanned: ${result.totalFiles}`);
  console.log(`Valid files: ${green(result.validFiles.toString())}`);
  console.log(`Files with issues: ${result.totalFiles - result.validFiles}`);
  console.log(`Errors: ${red(errorCount.toString())}`);
  console.log(`Warnings: ${yellow(warningCount.toString())}`);
  console.log();
  
  if (result.errors.length > 0) {
    console.log(bold("Issues Found:"));
    console.log("─".repeat(30));
    
    // Group errors by file
    const errorsByFile = new Map<string, ValidationError[]>();
    for (const error of result.errors) {
      if (!errorsByFile.has(error.file)) {
        errorsByFile.set(error.file, []);
      }
      errorsByFile.get(error.file)!.push(error);
    }
    
    for (const [file, fileErrors] of errorsByFile) {
      console.log(bold(`\n📄 ${file}`));
      for (const error of fileErrors) {
        const color = error.severity === "error" ? red : yellow;
        const icon = error.severity === "error" ? "❌" : "⚠️";
        console.log(`  ${icon} Line ${error.line}: ${color(error.error)}`);
      }
    }
  } else {
    console.log(green("✅ All modules are valid!"));
  }
}

/**
 * Main function
 */
async function main() {
  const args = Deno.args;
  const modulesPath = args[0] || "./modules";
  
  console.log(`Validating flake-parts modules in: ${modulesPath}`);
  console.log();
  
  // Check if modules directory exists
  try {
    const stat = await Deno.stat(modulesPath);
    if (!stat.isDirectory) {
      console.error(red(`Error: ${modulesPath} is not a directory`));
      Deno.exit(1);
    }
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      console.error(red(`Error: Modules directory not found: ${modulesPath}`));
      console.log("Please run this script from the project root or provide the path to modules directory");
    } else {
      console.error(red(`Error accessing modules directory: ${error.message}`));
    }
    Deno.exit(1);
  }
  
  const result = await validateModules(modulesPath);
  printResults(result);
  
  const errorCount = result.errors.filter(e => e.severity === "error").length;
  if (errorCount > 0) {
    Deno.exit(1);
  }
}

if (import.meta.main) {
  await main();
}