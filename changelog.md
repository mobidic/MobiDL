## 20191105 - modified vcf merging
rtg-tools merge was not satisfying and returned a bad number of AD fields when:
- one caller called 2 variants at one site
- the other one called only one variant
When merging, rtg retained the 2 variants but with AD of only one variant which triggered an error in bcftools.
So rtg-tools was replaced with GATK3 CombineVariants (not yet available in GATK4).
default options:
-genotypeMergeOptions UNSORTED
-mergeInfoWithMaxAC
-filteredRecordsMergeType KEEP\_IF\_ANY\_UNFILTERED
genotypeMergeOptions and filteredRecordsMergeType can be set via the json file.
[GATK doc](https://software.broadinstitute.org/gatk/documentation/tooldocs/3.8-0/org_broadinstitute_gatk_tools_walkers_variantutils_CombineVariants.php#--genotypemergeoption)