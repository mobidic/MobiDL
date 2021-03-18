task anacoreUtilsMergeVCFCallers {
	# global variables
	String SampleID
 	String OutDir
	String WorkflowType
  # task specific variables
	String Python3Exe
	File MergeVCFMobiDL
	Array[File] Vcfs
  Array[String] Callers
	# runtime attributes
	Int Cpu
	Int Memory
	command {
		# anacoreUtilsMergeVCFCallersMobiDL.py must be in PATH
		# and anacore-utils installed
		# https://github.com/bialimed/AnaCore-utils
		${Python3Exe} ${MergeVCFMobiDL} \
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
