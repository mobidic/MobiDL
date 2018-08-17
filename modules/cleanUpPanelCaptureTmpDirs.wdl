task cleanUpPanelCaptureTmpDirs {
	#global variables
	String SrunLow
	String SampleID	
	String OutDir
	String WorkflowType
	File FinalVcf
	Array[String] BamArray
	#String FinalBam
	#String FinalBamIndex
	#String FinalCram
	#String FinalCramIndex
	Array[String] VcfArray
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
		#File finalBam = "${FinalBam}"
		#File finalBamIndex = "${FinalBamIndex}"
		#File finalCram = "${FinalCram}"
		#File finalCramIndex = "${FinalCramIndex}"
		File finalVcf = "${FinalVcf}"
	}
}
