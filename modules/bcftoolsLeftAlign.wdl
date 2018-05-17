task bcftoolsLeftAlign {
  File BcftoolsExe 
  File FastaGenome
  File SplittedVcf
  String SrunLow 
  String WorkflowType
  String OutDir 
  String SampleID 

  command {
    ${SrunLow} ${BcftoolsExe} norm -f ${FastaGenome} \
    -o ${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_leftalign.vcf ${SplittedVcf}
  }
  output {
    File outBcfLeftAlign = "${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_leftalign.vcf"
  }
}
