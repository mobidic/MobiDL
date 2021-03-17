task cleanUpPanelCaptureTmpDirs {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	File FinalFile1
	File FinalFile2
	# File FinalFile3
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
		# echo " - SampleID.hc.vcf.gz is the same VCF as above, but bgzip compressed and tabix indexed (the SampleID.hc.vcf.gz.tbi file)." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo " - SampleID.dv.vcf is the vcf generated with DeepVariant." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		# echo " - SampleID.dv.vcf.gz is the same VCF as above, but bgzip compressed and tabix indexed (the SampleID.dv.vcf.gz.tbi.tbi file)." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo " - SampleID.vcf is the merged VCF containing bot DV and HC variants." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo " - SampleID.vcf.gz is the same VCF as above, but bgzip compressed and tabix indexed (the SampleID.vcf.gz.tbi file)." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
		echo "In the case you want to use the Captain Achab workflow use uncompressed VCF of your choice as input." >> "${OutDir}${SampleID}/${WorkflowType}/README_VCF.txt"
	}
	output {
		File finalFile1 = "${FinalFile1}"
		File finalFile2 = "${FinalFile2}"
		# File finalFile3 = "${FinalFile3}"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
