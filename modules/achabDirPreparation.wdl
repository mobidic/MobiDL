task achabDirPreparation {
  String WorkflowType
  String SampleID
  String OutDir
  String PhenolyzerExe
  File InputVcf

  #command {
  #  if [ ! -d "${OutDir}" ]; \
  #  then \
  #    mkdir "${OutDir}"; \
  #  fi
  #  if [ ! -d "${OutDir}${SampleID}" ]; \
  #  then \
  #    mkdir "${OutDir}${SampleID}"; \
  #  fi
  #  if [ ! -d "${OutDir}${SampleID}/${WorkflowType}" ]; then \
  #    mkdir "${OutDir}${SampleID}/${WorkflowType}";
  #  fi 
  #  if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/disease" ]; \
  #  then \
  #    mkdir "${OutDir}${SampleID}/${WorkflowType}/disease"; \
  #  fi
  #  if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/achab_excel" ]; \
  #  then \
  #    mkdir "${OutDir}${SampleID}/${WorkflowType}/achab_excel"; \
  #  fi
  #  if [ ! -d "${PhenolyzerExe}/out" ]; then \
  #    mkdir "${PhenolyzerExe}/out"; \
  #  fi
  #  if [ ! -d "${PhenolyzerExe}/out/disease" ]; then \
  #    mkdir "${PhenolyzerExe}/out/disease"; \
  #  fi
  #  if [ ! -d "${PhenolyzerExe}/disease_files" ]; then \
  #    mkdir "${PhenolyzerExe}/disease_files"; \
  #  fi
  #  if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/bcftools" ]; then \
  #    mkdir "${OutDir}${SampleID}/${WorkflowType}/bcftools"; \
  #  fi
  #  cp ${InputVcf} ${OutDir}${SampleID}/${WorkflowType}

  #}
  command {
    if [ ! -d "${OutDir}" ]; \
    then \
      mkdir "${OutDir}"; \
    fi
    if [ ! -d "${OutDir}${SampleID}" ]; \
    then \
      mkdir "${OutDir}${SampleID}"; \
    fi
    if [ ! -d "${OutDir}${SampleID}/${WorkflowType}" ]; then \
      mkdir "${OutDir}${SampleID}/${WorkflowType}";
    fi 
    if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/disease" ]; \
    then \
      mkdir "${OutDir}${SampleID}/${WorkflowType}/disease"; \
    fi
    if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/achab_excel" ]; \
    then \
      mkdir "${OutDir}${SampleID}/${WorkflowType}/achab_excel"; \
    fi
    if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/bcftools" ]; then \
      mkdir "${OutDir}${SampleID}/${WorkflowType}/bcftools"; \
    fi
    cp ${InputVcf} ${OutDir}${SampleID}/${WorkflowType}

  }
  output {
    Boolean isPrepared = true
  }
}
