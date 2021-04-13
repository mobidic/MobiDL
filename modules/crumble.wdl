task crumble {
	#global variables
	String SampleID
	String OutDir
	String OutDirSampleID = ""
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
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
		-O ${FileType},nthreads=${Cpu} ${InputFile} "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.crumble.${FileType}"
	}
	output {
		File crumbled = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.crumble.${FileType}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
