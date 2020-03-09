## 20200118 - Workflow: captainAchab; Annovar modules uses version with RefSeq
Until now annovar in achab did not use version number in RefSeq accession numbers (NM).
This is corrected using the pragma 'refgeneWithVer' in annovar MobiDL module (hg19 and hg38)

## 20191112 - Workflow: panelCapture; removed vcf merging
rtg-tools merge was not satisfying and returned a bad number of AD fields when:
- one caller called 2 variants at one site
- the other one called only one variant
When merging, rtg retained the 2 variants but with AD of only one variant which triggered an error in bcftools.
So rtg-tools was removed and as no satisfying merege method has yet been found, the qorkflow now outputs 2 files:
- the HaplotypeCaller vcf
- the DeepVariant vcf
