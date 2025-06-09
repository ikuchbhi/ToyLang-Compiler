import re
from nltk.tree import *
import sys

# Empty tree text by default, will be populated from file below
tree = ""
sanitized_tree = ""
output_file = input()

with open(output_file, "r") as f:
    found = False
    for line in f:
        if "((" in line:
            tree = line.replace("\n", "")
            break


# NLTK splits across " ", hence for every string in the tree, we need to replace " " with ""
# i.e. a string of the form "Hello World!" becomes "HelloWorld!"

if "print" in tree or "scan" in tree:
    pattern = re.compile(r'\"[^\"]+\"')

    def replace_spaces(match):
        return match[0].replace(" ", "")

    sanitized_tree = re.sub(pattern, replace_spaces, tree)
else:
    sanitized_tree = tree

# Corrected tree representation with explicit binary structure
# Route tree output directly to file instead of console
tree_output_file = "ast_tree.txt"  # or ask for input filename
with open(tree_output_file, 'w', encoding='utf-8') as f:
    original_stdout = sys.stdout
    sys.stdout = f
    Tree.fromstring(sanitized_tree, brackets='()', read_leaf=None, read_node=None).pretty_print(unicodelines=True, nodedist=5)
    sys.stdout = original_stdout

print(f"Tree saved to {tree_output_file}")