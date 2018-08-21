task gatkDepthOfCoverage {
	String SampleID
	String OutDir
	String JavaExe
	String JavaRam
	String GatkExe
	File RefFasta
	#runtime attributes
	Int Cpu
	Int Memory

	#must use gatk3 at the time
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
