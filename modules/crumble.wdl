task crumble {
	#global variables
	String SampleID
	String OutDir
	String WorkflowType
	
	#task specific variables
	File InputFile
	File InputFileIndex
	String CrumbleExe
	String FileType
	String LdLibraryPath
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		export LD_LIBRARY_PATH="${LdLibraryPath}"
		${CrumbleExe} \
		-O ${FileType},nthreads=${Cpu} ${InputFile} "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.crumble.${FileType}"       
	}
	output {
		File crumbled = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.crumble.${FileType}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
