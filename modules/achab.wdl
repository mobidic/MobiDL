task achab {

  File AchabExe
  File OutMpa
  File OutPhenolyzer
  Float AllelicFrequency
  String GenesOfInterest
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
<<<<<<< HEAD
    --candidates ${GenesOfInterest} \
=======
    -- candidates ${GenesOfInterest} \
>>>>>>> cb360481efb284d326bd9dc67f5a26dcc454b975
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
