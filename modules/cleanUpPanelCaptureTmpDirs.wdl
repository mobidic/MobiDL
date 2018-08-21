task cleanUpPanelCaptureTmpDirs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	File FinalVcf
	Array[String] BamArray
	Array[String] VcfArray
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		if [ -d "${OutDir}${SampleID}/${WorkflowType}/splitted_intervals" ];then \
			rm -r "${OutDir}${SampleID}/${WorkflowType}/splitted_intervals"; \
		fi
		if [ -d "${OutDir}${SampleID}/${WorkflowType}/recal_tables" ];then \
			rm -r "${OutDir}${SampleID}/${WorkflowType}/recal_tables"; \
		fi
		if [ -d "${OutDir}${SampleID}/${WorkflowType}/recal_bams" ];then \
			rm -r "${OutDir}${SampleID}/${WorkflowType}/recal_bams"; \
		fi
		if [ -d "${OutDir}${SampleID}/${WorkflowType}/vcfs" ];then \
			rm -r "${OutDir}${SampleID}/${WorkflowType}/vcfs"; \
		fi
		rm ${sep=" " BamArray}
	  rm ${sep=" " VcfArray}
	}
	output {
		File finalVcf = "${FinalVcf}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
