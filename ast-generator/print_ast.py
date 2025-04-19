import re
from nltk.tree import *

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
Tree.fromstring(sanitized_tree, brackets='()', read_leaf=None, read_node=None).pretty_print(unicodelines=True, nodedist=5)
