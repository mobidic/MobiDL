task bwaSamtools {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	File FastqR1
	File FastqR2
	String SamtoolsExe
	#task specific variables
	String BwaExe
	String Platform
	File RefFasta
	#File RefFai
	#RefFai useles for bwa
	#index files for bwa
	File RefAmb
	File RefAnn
	File RefBwt
	File RefPac
	File RefSa
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${BwaExe} mem -M -t ${Cpu} \
		-R "@RG\tID:${SampleID}\tSM:${SampleID}\tPL:${Platform}" \
		${RefFasta} \
		${FastqR1} \
		${FastqR2} \
		| ${SamtoolsExe} sort -@ ${Cpu} -l 1 \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
	}
	output {
		File sortedBam = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.bam"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
