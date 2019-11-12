task bcftoolsStats {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String BcfToolsExe
	#task specific variables
	File VcfFile
	File VcfFileIndex
	String VcSuffix
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${BcfToolsExe} stats \
		${VcfFile} \
		> "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}${VcSuffix}.stats.txt"
	}
	output {
		File statVcf = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}${VcSuffix}.stats.txt"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
