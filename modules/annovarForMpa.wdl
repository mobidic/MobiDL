task annovarForMpa {

  #perl path/to/table_annovar.pl path/to/example.vcf humandb/ -buildver hg19 -out path/to/output/name -remove -protocol refGene,refGene,clinvar_20170905,dbnsfp33a,spidex,dbscsnv11,gnomad_exome,gnomad_genome,intervar_20180118 -operation gx,g,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -arg '-splicing 20','-hgvs',,,,,,, -xref example/gene_customfullxref.txt
  File CustomXref
  File SortedVcf
  File RefAnnotateVariation
  File RefCodingChange
  File RefConvert2Annovar
  File RefRetrieveSeqFromFasta
  File RefVariantsReduction
  File TableAnnovarExe
  String SrunLow
  String WorkflowType 
  String HumanDb
  String SampleID
  String OutDir
  String PerlPath

  command <<<
    ${SrunLow} ${PerlPath} ${TableAnnovarExe} \
    ${SortedVcf} \
    ${HumanDb} \
    -buildver hg19 \
    -out ${OutDir}${SampleID}/${WorkflowType}/${SampleID} \
    -remove \
    -protocol refGene,refGene,clinvar_20170905,dbnsfp33a,spidex,dbscsnv11,gnomad_exome,gnomad_genome,intervar_20180118 -operation gx,g,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -arg '-splicing 20','-hgvs',,,,,,, \
    -xref ${CustomXref}
  >>>

  output {
    File outAnnotationVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.vcf"
    File outAnnotationAvinput = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.avinput"
    File outAnnotationTxt = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno.txt"
  }
}
