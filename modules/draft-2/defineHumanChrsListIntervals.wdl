task defineHumanChrsListIntervals {
  ## Task to return a glob containing human chr gatk intervals list files
	# i.e. chr1.list containing "chr1" until chrM.list
	# to be used for alignment management to avoid splitting of the bam files
	##global variables
	#task specific variables
	String HumanChrListPath
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		echo "1"
	}
	output {
		Array[File] humanChrsListIntervals = glob("${HumanChrListPath}/chr*.list")
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
