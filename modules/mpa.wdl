task mpa {
	File MpaExe
	File OutAnnotation
	String WorkflowType
	String SampleID
	String OutDir
	String PythonPath
	String Genome
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		"${PythonPath}" "${MpaExe}" \
		-i "${OutAnnotation}" \
		-o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.${Genome}_multianno_MPA.vcf"
	}
	output {
		File outMpa = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.hg19_multianno_MPA.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
