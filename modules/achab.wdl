task achab {

 File AchabExe
 File OutMpa
 String? OutPhenolyzer
 String CustomVCF
 String GenesOfInterest
 Float AllelicFrequency
 Float MozaicRate
 Float MozaicDP
 String CnvGeneList
 String FilterList
 String FatherSample
 String CaseSample
 String MotherSample
 String WorkflowType
 String CheckTrio
 String CustomInfo
 String SampleID
 String OutDir
 String PerlPath
 #runtime attributes
 Int Cpu
 Int Memory

 command {
   ${PerlPath} ${AchabExe} \
  --vcf ${OutMpa} \
  --outDir ${OutDir}${SampleID}/${WorkflowType}/achab_excel/ \
  --outPrefix ${SampleID} \
  --case ${CaseSample} \
  --dad ${FatherSample} \
  --mum ${MotherSample} \
  ${CheckTrio} \
  --candidates ${GenesOfInterest} \
  --phenolyzerFile ${OutPhenolyzer} \
  --popFreqThr ${AllelicFrequency} \
  --filterList ${FilterList} \
  --cnvGeneList ${CnvGeneList} \
  --customVCF ${CustomVCF} \
  --mozaicRate ${MozaicRate} \
  --mozaicDP ${MozaicDP} \
  --customInfoList ${CustomInfo}
 }
 output {
  File outAchab = "${OutDir}${SampleID}/${WorkflowType}/achab_excel/${SampleID}_achab_catch.xlsx"
 }
 runtime {                                                                                                                                                                    
  cpu: "${Cpu}"
  requested_memory_mb_per_core: "${Memory}"
 }
}
