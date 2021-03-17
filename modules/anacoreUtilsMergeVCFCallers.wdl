task anacoreUtilsMergeVCFCallers {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
  #task specific variables
	Array[File] Vcfs
  Array[File] Callers
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		anacoreUtilsMergeVCFCallers \
    -c ${sep=' ' Callers} \
		-i ${sep=' ' Vcfs} \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.merged.vcf"
	}
	output {
		File mergedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.merged.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
