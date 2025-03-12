#!/usr/bin/env python3


import sys
import json  # Better to use dedicated package to write JSON
from peds import open_ped  # pip install peds
from peds import get_probands


# MAIN:
families = open_ped(sys.argv[1])


# Group individuals of each family in a list:
fam_list = []
for fam in families:
    fam_list.append([memb.id for memb in fam])

if len(fam_list) == 0:
    sys.exit("Families should not be empty -> EXIT")

with open('families.json', 'w') as families_out:
    families_out.write(json.dumps(fam_list) + '\n')


# Extract 'status' of each family = casIndex, father, mother and affected_list:
status_list = []
for i, fam in enumerate(families):
    casIndex = fam.get_proband()
    assert casIndex.id == fam_list[i][0], "CasIndex should also be 1st indiv of family"

    # Father and Mother can be 'None' -> check it:
    father = fam.get_father(casIndex)
    father_ID = father.id if father is not None else ""
    mother = fam.get_mother(casIndex)
    mother_ID = mother.id if mother is not None else ""

    affected = [memb.id for memb in fam if memb.is_affected()]

    # casIndex ; father ; mother ; affected_list
    status_list.append([casIndex.id, father_ID, mother_ID, ",".join(affected)])

with open('status.json', 'w') as status_out:
    status_out.write(json.dumps(status_list) + '\n')


# Sanity check:
assert len(fam_list) == len(status_list), "Family_list and status_list have different length"
