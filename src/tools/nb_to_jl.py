#
# utility to convert julia notebook to a julia file
#

import nbformat
import argparse
import os

def convert_notebook_to_julia(notebook_path, output_path):
    # Read the notebook
    with open(notebook_path, 'r', encoding='utf-8') as f:
        nb = nbformat.read(f, as_version=4)

    # Extract code cells and write to the output file
    with open(output_path, 'w', encoding='utf-8') as f:
        for cell in nb.cells:
            if cell.cell_type == 'code':
                f.write(cell.source + '\n\n')

def main():
    parser = argparse.ArgumentParser(description="Convert Jupyter notebook to Julia script.")
    parser.add_argument("notebook", help="The input notebook file (.ipynb)")
    args = parser.parse_args()

    notebook_path = args.notebook
    if not notebook_path.endswith(".ipynb"):
        raise ValueError("Input file must have a .ipynb extension")

    output_path = os.path.splitext(notebook_path)[0] + ".jl"

    convert_notebook_to_julia(notebook_path, output_path)
    print(f"Converted {notebook_path} to {output_path}")

if __name__ == "__main__":
    main()
