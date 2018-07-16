task achab {

  File AchabExe
  File OutMpa
  File? OutPhenolyzer
  Float AllelicFrequency
  File? GenesOfInterest
  String CnvGeneList
  String FilterList
  String FatherSample
  String CaseSample
  String MotherSample
  String SrunLow 
  String WorkflowType
  String CheckTrio
  String CustomInfo
  String SampleID
  String OutDir
  String PerlPath


  command {
    ${SrunLow} ${PerlPath} ${AchabExe} \
    --vcf ${OutMpa} \
    --outDir ${OutDir}${SampleID}/${WorkflowType}/achab_excel/ \
    --case ${CaseSample} \
    --dad ${FatherSample} \
    --mum ${MotherSample} \
    ${CheckTrio} \
    --candidates ${GenesOfInterest} \
    --phenolyzerFile ${OutPhenolyzer} \
    --popFreqThr ${AllelicFrequency} \
    --filterList ${FilterList} \
    --cnvGeneList ${CnvGeneList}\
    --customInfoList ${CustomInfo} 
  }
  output {
    File outAchab = "${OutDir}${SampleID}/${WorkflowType}/achab_excel/achab_catch.xlsx"
  }
}
