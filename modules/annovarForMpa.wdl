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
 String GnomadExome
 String GnomadGenome
 String PopFreqMax
 String Intervar
 #String OperationSuffix = ",f"
 #String Comma = ","
 String Dollar = "$"
  #-protocol refGene,refGene,clinvar_20180603,dbnsfp33a,spidex,dbscsnv11,gnomad_exome,gnomad_genome,popfreq_max_20150413,intervar_20180118 -operation gx,g,f,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -arg '-splicing 100','-hgvs',,,,,,,, \
  #-protocol refGene,refGene,"${Clinvar}","${Dbnsfp}","${Spidex}","${Dbscsnv}","${Gnomad_exome}","${Gnomad_genome}","${Intervar}","${Pop_freq_max}" -operation gx,g,f,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -arg '-splicing 100','-hgvs',,,,,,,, \
 command <<<
	OPERATION_SUFFIX=',f'
	COMMA=','
	POPFREQMAX=',"${PopFreqMax}"'
	SPIDEX=',"${Spidex}"'
  if [ ${Genome} == 'hg38' ];then
		OPERATION_SUFFIX=''
		COMMA=''
		POPFREQMAX=''
		SPIDEX=''
	fi
  "${PerlPath}" "${TableAnnovarExe}" \
  "${SortedVcf}" \
  "${HumanDb}" \
  -buildver "${Genome}" \
  -out "${OutDir}${SampleID}/${WorkflowType}/${SampleID}" \
  -remove \
  -protocol refGene,refGene,"${Clinvar}","${Dbnsfp}","${Dbscsnv}","${GnomadExome}","${GnomadGenome}","${Intervar}""${Dollar}{SPIDEX}""${Dollar}{POPFREQMAX}" -operation gx,g,f,f,f,f,f,f"${Dollar}{OPERATION_SUFFIX}""${Dollar}{OPERATION_SUFFIX}" -nastring . -vcfinput -otherinfo -arg '-splicing 100','-hgvs',,,,,,"${Dollar}{COMMA}""${Dollar}{COMMA}" \
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
