## 20191112 - removed vcf merging
rtg-tools merge was not satisfying and returned a bad number of AD fields when:
- one caller called 2 variants at one site
- the other one called only one variant
When merging, rtg retained the 2 variants but with AD of only one variant which triggered an error in bcftools.
So rtg-tools was removed and as no satisfying merege method has yet been found, the qorkflow now outputs 2 files:
- the HaplotypeCaller vcf
- the DeepVariant vcf
