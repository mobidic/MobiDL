task preparePanelCaptureTmpDirs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		if [ ! -d "${OutDir}" ];then \
			mkdir "${OutDir}"; \
		fi
		if [ ! -d "${OutDir}${SampleID}" ];then \
			mkdir "${OutDir}${SampleID}"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/FastqcDir" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/FastqcDir"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/splitted_intervals" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/splitted_intervals"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/recal_tables" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/recal_tables"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/recal_bams" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/recal_bams"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/qualimap" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/qualimap"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/vcfs" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/vcfs"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/intervals" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/intervals"; \
		fi
		if [ ! -d "${OutDir}${SampleID}/${WorkflowType}/coverage" ];then \
			mkdir "${OutDir}${SampleID}/${WorkflowType}/coverage"; \
		fi
	}
	output {
		Boolean dirsPrepared = true
		#we put all tmp dirs (that will be removed at the end of the workflow to force execution of the module when call-caching activated
		File outDir = "${OutDir}"
		File sampleDir = "${OutDir}${SampleID}"
		File workflowTypeDir = "${OutDir}${SampleID}/${WorkflowType}"
		File recalTablesDir = "${OutDir}${SampleID}/${WorkflowType}/recal_tables"
		File splittedIntervalsDir = "${OutDir}${SampleID}/${WorkflowType}/splitted_intervals"
		File recalBamsDir = "${OutDir}${SampleID}/${WorkflowType}/recal_bams"
		File vcfDir = "${OutDir}${SampleID}/${WorkflowType}/vcfs"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
