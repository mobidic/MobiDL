#!/usr/bin/env python3


import sys
import json  # Better to use dedicated package to write JSON
from peds import open_ped  # pip install peds
from peds import get_probands


# MAIN:
families = open_ped(sys.argv[1])


status_list = []

for fam in families:
    # Group individuals of each family in a list:
    members_list = [memb.id for memb in fam]
    assert len(members_list) != 0, "Empty family is impossible"

    # Extract 'status' of each family = casIndex, father, mother and affected_list:
    casIndex = fam.get_proband()
    assert casIndex.id == members_list[0], "CasIndex should also be 1st indiv of family"

    # Father and Mother can be 'None' -> check it:
    father = fam.get_father(casIndex)
    father_ID = father.id if father is not None else ""
    mother = fam.get_mother(casIndex)
    mother_ID = mother.id if mother is not None else ""

    affected = [memb.id for memb in fam if memb.is_affected()]

    # members_list ; casIndex ; father ; mother ; affected_list
    status_list.append([",".join(members_list), casIndex.id, father_ID, mother_ID, ",".join(affected)])


with open('status.json', 'w') as status_out:
    status_out.write(json.dumps(status_list) + '\n')
