task bcftoolsSplit {
 String WorkflowType
 Boolean IsPrepared
 File InputVcf
 File BcftoolsExe
 String SampleID
 String OutDir
 #runtime attributes
 Int Cpu
 Int Memory

 command {
  ${BcftoolsExe} norm -m-both \
  -o ${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_splitted.vcf ${InputVcf}
 }
 output {
  File outBcfSplit = "${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_splitted.vcf"
 }
 runtime {                                                                                                                                                                    
  cpu: "${Cpu}"
  requested_memory_mb_per_core: "${Memory}"
 }
}

