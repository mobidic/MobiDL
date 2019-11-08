task cleanUpPanelCaptureTmpDirs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	File FinalFile1
	File FinalFile2
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
		echo "#####MobiDL panelCapture November 2019" > "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo "You will Find several vcf files in the directory, MobiDL using two variant callers:" >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo " - SampleID.hc.vcf is the vcf genereated with GATK4 HaplotypeCaller." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo " - SampleID.dv.vcf is the vcf generated with DeepVariant." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo " - SampleID.vcf, SampleID.vcf.gz are the same files, the results of the 2 callers being merged (the.gz is the bgzip compressed version)." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo "In the FORMAT field, two 'samples' are present, one for each caller."  >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo "The SampleID.vcf.idx and SampleID.vcf.gz.tbi are index files, not useful by themselves." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"		
		echo "In the case you want to use the Captain Achab trio capabilities, do not use the merged file, and in any case, use uncompressed VCF as input." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
	}
	output {
		File finalFile1 = "${FinalFile1}"
		File finalFile2 = "${FinalFile2}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
