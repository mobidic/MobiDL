task annovarForMpa {

 File CustomXref
 File SortedVcf
 File RefAnnotateVariation
 File RefCodingChange
 File RefConvert2Annovar
 File RefRetrieveSeqFromFasta
 File RefVariantsReduction
 File TableAnnovarExe
 String WorkflowType
 String HumanDb
 String SampleID
 String OutDir
 String PerlPath
 #runtime attributes
 Int Cpu
 Int Memory

 command <<<
   ${PerlPath} ${TableAnnovarExe} \
  ${SortedVcf} \
  ${HumanDb} \
  -buildver hg19 \
  -out ${OutDir}${SampleID}/${WorkflowType}/${SampleID} \
  -remove \
  -protocol refGene,refGene,clinvar_20180603,dbnsfp33a,spidex,dbscsnv11,gnomad_exome,gnomad_genome,intervar_20180118 -operation gx,g,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -arg '-splicing 20','-hgvs',,,,,,, \
  -xref ${CustomXref}
 >>>

 output {
  File outAnnotationVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.vcf"
  File outAnnotationAvinput = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.avinput"
  File outAnnotationTxt = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.txt"
 }
 runtime {                                                                                                                                                                    
  cpu: "${Cpu}"
  requested_memory_mb_per_core: "${Memory}"
 }
}
