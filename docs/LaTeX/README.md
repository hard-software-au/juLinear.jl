# LaTeX Folder

This folder contains LaTeX files used for documenting and presenting linear programming formulations and related content.

## Files

- **`jlcode.sty`**: This is a custom LaTeX package used to provide syntactic highlighting for code blocks within `.tex` files. It is particularly useful for enhancing the readability and presentation of code snippets embedded in LaTeX documents.

- **`LP_Formulation.tex`**: This LaTeX file contains the formulation of a linear programming (LP) problem. The document is structured to present the mathematical model, including objective functions, constraints, and variables. The `jlcode.sty` package is utilized within this file to highlight code snippets for better clarity.

## Usage

To compile the LaTeX document (`LP_Formulation.tex`), ensure that the `jlcode.sty` file is in the same directory. The syntactic highlighting will automatically be applied to any code snippets in the `.tex` file.

<details>
  <summary><strong>Method 1: Compiling with Visual Studio Code</strong></summary>

### 1. Install VSCode

If you haven't already, download and install Visual Studio Code from [here](https://code.visualstudio.com/).

### 2. Install LaTeX Workshop Extension

1. Open VSCode.
2. Go to the Extensions view by clicking on the Extensions icon in the Activity Bar on the side of the window or by pressing `Ctrl+Shift+X`.
3. In the search bar, type `LaTeX Workshop`.
4. Click on `Install` to add the LaTeX Workshop extension.

### 3. Set Up LaTeX Distribution

Make sure you have a LaTeX distribution installed on your system:
- For **Windows**: Install [MiKTeX](https://miktex.org/download).
- For **macOS**: Install [MacTeX](http://www.tug.org/mactex/).
- For **Linux**: Install TeX Live via your package manager (e.g., `sudo apt-get install texlive-full` for Debian-based systems).

### 4. Open the `.tex` File in VSCode

1. Open the LaTeX folder in VSCode.
2. Click on the `LP_Formulation.tex` file to open it in the editor.

### 5. Compile the Document

1. With `LP_Formulation.tex` open, press `Ctrl+Alt+B` to compile the document.
2. The LaTeX Workshop extension will automatically compile the `.tex` file and generate a PDF output.
3. The output PDF will be displayed in the built-in PDF viewer within VSCode.

### 6. View the Output

Once the compilation is complete, you can view the PDF directly in VSCode's PDF viewer or open it with any external PDF viewer.

</details>

<details>
  <summary><strong>Method 2: Compiling with Overleaf</strong></summary>

### 1. Create an Overleaf Account

If you don’t have an Overleaf account, sign up for free at [Overleaf](https://www.overleaf.com/).

### 2. Create a New Project

1. Log in to your Overleaf account.
2. On the dashboard, click on `New Project`.
3. Select `Upload Project` from the dropdown menu.

### 3. Upload Files

1. Upload both `LP_Formulation.tex` and `jlcode.sty` files.
2. Ensure that `jlcode.sty` is in the same directory as `LP_Formulation.tex` within the project.

### 4. Compile the Document

1. Open `LP_Formulation.tex` in the Overleaf editor.
2. The document will automatically compile, and the output will be displayed in the right-hand pane.
3. If the document doesn't compile automatically, click on the `Recompile` button at the top of the editor.

### 5. Download the PDF

Once the compilation is complete, you can download the generated PDF by clicking on the `Download PDF` button.

</details>

## Notes

- Ensure that the `jlcode.sty` file remains in the same directory as your `.tex` files to apply the syntactic highlighting correctly.
- If you encounter any issues during compilation in VSCode, check the LaTeX Workshop extension logs for error messages.
- Overleaf automatically handles LaTeX distribution and package management, so you don’t need to worry about setting up a local LaTeX environment.

