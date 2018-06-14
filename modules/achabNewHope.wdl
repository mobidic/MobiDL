task achabNewHope {

  File AchabExe
  File OutMpa
  File OutPhenolyzer
  String CnvGeneList
  String FilterList 
  String GenesOfInterest
  String FatherSample
  String CaseSample
  String MotherSample
  Float AllelicFrequency
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
    --newHope \
    --filterList ${FilterList} \
    --cnvGeneList ${CnvGeneList}\
    --customInfoList ${CustomInfo} 

  }
  output {
    File outAchabNewHope = "${OutDir}${SampleID}/${WorkflowType}/achab_excel/achab_catch_newHope.xlsx"
  }
}
