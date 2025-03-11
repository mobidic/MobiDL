#!/usr/bin/env python3


import sys
import json  # Better to use dedicated package to write JSON
from peds import open_ped  # pip install peds
from peds import get_probands


# MAIN:
families = open_ped(sys.argv[1])

fam_list = []
for fam in families:
    fam_list.append([memb.id for memb in fam])

if len(fam_list) == 0:
    sys.exit("Families should not be empty -> EXIT")


with open('families.json', 'w') as families:
    families.write(json.dumps(fam_list) + '\n')
