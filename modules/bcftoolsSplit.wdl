task bcftoolsSplit {

  String SrunLow
  String WorkflowType
  Boolean IsPrepared
  File InputVcf
	File BcftoolsExe
  String SampleID 
  String OutDir
  

	command {
    ${SrunLow} ${BcftoolsExe} norm -m-both \
    -o ${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_splitted.vcf ${InputVcf} 
	}	
  output {
    File outBcfSplit = "${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_splitted.vcf"
  }

}

