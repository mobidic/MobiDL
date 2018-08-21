task bcftoolsLeftAlign {
 File BcftoolsExe  File FastaGenome
 File SplittedVcf
 String WorkflowType
 String OutDir
 String SampleID
 #runtime attributes
 Int Cpu
 Int Memory
 command {
   ${BcftoolsExe} norm -f ${FastaGenome} \
  -o ${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_leftalign.vcf ${SplittedVcf}
 }
 output {
  File outBcfLeftAlign = "${OutDir}${SampleID}/${WorkflowType}/bcftools/${SampleID}_leftalign.vcf"
 }
 runtime {                                                                                                                                                                    
  cpu: "${Cpu}"
  requested_memory_mb_per_core: "${Memory}"
 }
}
