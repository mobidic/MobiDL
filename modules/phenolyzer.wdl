task phenolyzer {

  #perl disease_annotation.pl disease.txt -f -p -ph -logistic -out disease/out

  Boolean IsPrepared
  File? PhenolyzerExe
  File? DiseaseFile
  String SrunLow
  String WorkflowType
  String SampleID
  String OutDir
  String PerlPath

  command <<<
    cd ${PhenolyzerExe}
    ${SrunLow} ${PerlPath} disease_annotation.pl ${DiseaseFile} -f -p -ph -logistic -out ../..${OutDir}${SampleID}/${WorkflowType}/disease/${SampleID}
  >>>

  output {
    File outPhenolyzer = "${OutDir}${SampleID}/${WorkflowType}/disease/${SampleID}.predicted_gene_scores"
  }
}
