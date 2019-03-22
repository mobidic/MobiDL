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
 #dataabses
 String Genome
 String Clinvar
 String Dbnsfp
 String Spidex
 String Dbscsnv
 String Gnomad_exome
 String Gnomad_genome
 String Pop_freq_max
 String Intervar
 #String OperationSuffix
 #String Comma
  #-protocol refGene,refGene,clinvar_20180603,dbnsfp33a,spidex,dbscsnv11,gnomad_exome,gnomad_genome,popfreq_max_20150413,intervar_20180118 -operation gx,g,f,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -arg '-splicing 100','-hgvs',,,,,,,, \
 command <<<
   "${PerlPath}" "${TableAnnovarExe}" \
  "${SortedVcf}" \
  "${HumanDb}" \
  -buildver "${Genome}" \
  -out "${OutDir}${SampleID}/${WorkflowType}/${SampleID}" \
  -remove \
  -protocol refGene,refGene,"${Clinvar}","${Dbnsfp}","${Spidex}","${Dbscsnv}","${Gnomad_exome}","${Gnomad_genome}","${Intervar}","${Pop_freq_max}" -operation gx,g,f,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -arg '-splicing 100','-hgvs',,,,,,,, \
  -xref "${CustomXref}"
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
