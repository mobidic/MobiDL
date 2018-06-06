task achab {

  #Trio = dad/mum/case mais si control, trio ne marche pas

  File AchabExe
  String GenesOfInterest
  #String ControlSample
  String FatherSample
  String CaseSample
  String MotherSample
  File OutMpa
  File OutPhenolyzer
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
    --customInfo ${CustomInfo} \
  }
  output {
    File outAchab = "${OutDir}${SampleID}/${WorkflowType}/achab_excel/achab_catch.xlsx"
  }
}
