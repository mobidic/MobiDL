task phenolyzer {

  #perl disease_annotation.pl disease.txt -f -p -ph -logistic -out disease/out

  # Phenolyzer a été conçu de sorte à ce que tout le traitement se fasse dans son répertoire, on ne peut pas passer par les liens de Cromwell.
  # On réaliser donc la commande cd pour travailler dans le répertoire de Phenolyzer et on utilise mv pour transférer tous les outputs vers notre dossier output désiré.
  #
  Boolean IsPrepared
  String PhenolyzerExe
  File DiseaseFile
  String SrunLow
  String WorkflowType
  String SampleID
  String OutDir
  String PerlPath

  command <<<
    cp ${DiseaseFile} ${PhenolyzerExe}/disease_files
    chmod +xwr ${PhenolyzerExe}/disease_files/disease.txt
    cd ${PhenolyzerExe}
    ${SrunLow} ${PerlPath} disease_annotation.pl disease_files/disease.txt -f -p -ph -logistic -out out/disease/${SampleID}
    mv ${PhenolyzerExe}/out/disease/${SampleID}.predicted_gene_scores ${OutDir}${SampleID}/${WorkflowType}/disease/
  >>>

  output {
    File outPhenolyzer = "${OutDir}${SampleID}/${WorkflowType}/disease/${SampleID}.predicted_gene_scores"
  }
}
