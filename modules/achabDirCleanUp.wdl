task achabDirCleanUp {
  String WorkflowType
  String SampleID
  String OutDir
  String PhenolyzerExe
  File OutPhenolyzer
  File OutAchab
  File OutAchabNewHope

  #if [ -d "${PhenolyzerExe}/out" ]; then \
  #    rm -rf "${PhenolyzerExe}/out"; \
  #  fi
  #  if [ -d "${PhenolyzerExe}/out/disease" ]; then \
  #    rm -rf "${PhenolyzerExe}/out/disease"; \
  #  fi
  #  if [ -d "${PhenolyzerExe}/disease_files" ]; then \
  #    rm -rf "${PhenolyzerExe}/disease_files"; \
  #  fi
  #  if [ -f "${PhenolyzerExe}/disease.txt" ]; then \
  #    rm "${PhenolyzerExe}/disease.txt"; \
  #  fi


  command {
    if [ -d "${OutDir}${SampleID}/${WorkflowType}/bcftools" ]; then \
      rm -rf "${OutDir}${SampleID}/${WorkflowType}/bcftools"; \
    fi 
    if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.avinput" ]; then \
      rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.avinput"; \
    fi 
    if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.txt" ]; then \
      rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.txt"; \
    fi 
    if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.vcf" ]; then \
      rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.vcf"; \
    fi 
    if [ -f "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf" ]; then \
      rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf"; \
    fi
    if [ -f "${OutDir}${SampleID}/${SampleID}.sorted.vcf.idx" ]; then \
      rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sorted.vcf.idx"; \
    fi
  }
  output {
    Boolean isRemoved = true
  }
}
