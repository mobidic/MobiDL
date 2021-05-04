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
 Int CpuHigh
 Int Memory
 #databases
 String Genome
 Int IntronHgvs = 80
 String Clinvar = 'clinvar_latest'
 String Dbnsfp
 #String Spidex
 String Dbscsnv
 String GnomadExome
 String GnomadGenome
 String PopFreqMax
 String Intervar
 String SpliceAI
 String Dollar = "$"
 command <<<
  OPERATION_SUFFIX=',f'
  COMMA=','
  POPFREQMAX=',${PopFreqMax}'
  #REFGENE='refGeneWithVer'
  if [ ${Genome} == 'hg38' ];then
    OPERATION_SUFFIX=''
    COMMA=''
    POPFREQMAX=''
    #REFGENE='refGene'
  fi
  if [[ "${Clinvar}" == 'clinvar_latest' ]] && [[ -f "${HumanDb}/${Genome}_clinvar_latest.ver" ]]; then
    mkdir "${OutDir}${SampleID}/${WorkflowType}/admin"
    cp "${HumanDb}/${Genome}_clinvar_latest.ver" "${OutDir}${SampleID}/${WorkflowType}/admin/"
  fi
  "${PerlPath}" "${TableAnnovarExe}" \
  "${SortedVcf}" \
  "${HumanDb}" \
  -thread "${CpuHigh}" \
  -buildver "${Genome}" \
  -out "${OutDir}${SampleID}/${WorkflowType}/${SampleID}" \
  -remove \
  -intronhgvs "${IntronHgvs}" \
  -protocol refGeneWithVer,refGeneWithVer,refGeneWithVer,"${Clinvar}","${Dbnsfp}","${Dbscsnv}","${GnomadExome}","${GnomadGenome}","${Intervar}",regsnpintron,"${SpliceAI}""${Dollar}{POPFREQMAX}" \
  -operation gx,g,g,f,f,f,f,f,f,f,f"${Dollar}{OPERATION_SUFFIX}" \
  -nastring . \
  -vcfinput \
  -otherinfo \
  -arg '-splicing 5','-hgvs','-memtotal ${Memory}000',,,,,,,,"${Dollar}{COMMA}" \
  -xref "${CustomXref}"
 >>>
# command <<<
#  OPERATION_SUFFIX=',f'
#  COMMA=','
#  POPFREQMAX=',${PopFreqMax}'
#  #REFGENE='refGeneWithVer'
#  if [ "~{Genome}" == 'hg38' ];then
#    OPERATION_SUFFIX=''
#    COMMA=''
#    POPFREQMAX=''
#    #REFGENE='refGene'
#  fi
#  if [ "~{Clinvar}" == 'clinvar_latest' ] and [ -f "~{HumanDb}/~{Genome}_clinvar_latest.ver" ]; then
#     cp "~{HumanDb}/~{Genome}_clinvar_latest.ver" "~{OutDir}~{SampleID}/~{WorkflowType}/"
#  fi
#  "~{PerlPath}" "~{TableAnnovarExe}" \
#  "~{SortedVcf}" \
#  "~{HumanDb}" \
#  -thread "~{CpuHigh}" \
#  -buildver "~{Genome}" \
#  -out "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}" \
#  -remove \
#  -intronhgvs "~{IntronHgvs}" \
#  -protocol #refGeneWithVer,refGeneWithVer,refGeneWithVer,"~{Clinvar}","~{Dbnsfp}","~{Dbscsnv}","~{GnomadExome}","~{GnomadGen#ome}","~{Intervar}",regsnpintron,"~{SpliceAI}""$POPFREQMAX" \
#  -operation gx,g,g,f,f,f,f,f,f,f,f"$OPERATION_SUFFIX" \
#  -nastring . \
#  -vcfinput \
#  -otherinfo \
#  -arg '-splicing 5','-hgvs','-memtotal ~{Memory}000',,,,,,,,"$COMMA" \
#  -xref "~{CustomXref}"
# >>>

 output {
  File outAnnotationVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.${Genome}_multianno.vcf"
  File outAnnotationAvinput = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.avinput"
  File outAnnotationTxt = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.${Genome}_multianno.txt"
 }
 runtime {
  cpu: "${CpuHigh}"
  requested_memory_mb_per_core: "${Memory}"
 }
}
