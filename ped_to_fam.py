#!/usr/bin/env python3


import sys
import json  # Better to use dedicated package to write JSON
from peds import open_ped  # pip install peds
from peds import get_probands


# MAIN:
families = open_ped(sys.argv[1])


# Extract 'status' of each family = casIndex, members_list, father, mother and affected_list:
status_list = []
for fam in families:
    all_members = [memb.id for memb in fam]

    if len(all_members) == 1:  # Family with 1 single sample
        affected = [memb.id for memb in fam if memb.is_affected()]
        status_list.append([all_members[0], all_members[0], "", "", ",".join(affected)])

    else:
        casIndex = fam.get_proband()
        if casIndex is None:  # = NO affected person in fam
            print(f"WARN: No proband found in family {fam.id} -> Take 1st member instead")
            casIndex = [indiv for indiv in fam][0]  # -> Take 1st sample instead

        # Father and Mother can be 'None' -> check it:
        father = fam.get_father(casIndex)
        father_ID = father.id if father is not None else ""
        mother = fam.get_mother(casIndex)
        mother_ID = mother.id if mother is not None else ""

        affected = [memb.id for memb in fam if memb.is_affected()]

        assert casIndex.id == all_members[0], "CasIndex should also be 1st indiv of family"

        # Format = casIndex ; members_list ; father ; mother ; affected_list
        status_list.append([casIndex.id, ",".join(all_members), father_ID, mother_ID, ",".join(affected)])


# Write out file:
with open('status.json', 'w') as status_out:
    status_out.write(json.dumps(status_list) + '\n')
