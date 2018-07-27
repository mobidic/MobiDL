task phenolyzer {

  Boolean IsPrepared
  String PhenolyzerExe
  String DiseaseFile
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
    String? outPhenolyzer = "${OutDir}${SampleID}/${WorkflowType}/disease/${SampleID}.predicted_gene_scores"
  }
}
