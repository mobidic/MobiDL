version 1.0

task cleanUpPanelCaptureTmpDirs {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-05"
	}
	input {
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		# task specific variables
		String JavaExe
		String CromwellJar
		File FinalFile1
		File? FinalFile2
		Array[String] BamArray
		Array[String] VcfArray
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		if [ -d "~{OutDir}~{SampleID}/~{WorkflowType}/splitted_intervals" ];then \
			rm -r "~{OutDir}~{SampleID}/~{WorkflowType}/splitted_intervals"; \
		fi
		if [ -d "~{OutDir}~{SampleID}/~{WorkflowType}/recal_tables" ];then \
			rm -r "~{OutDir}~{SampleID}/~{WorkflowType}/recal_tables"; \
		fi
		if [ -d "~{OutDir}~{SampleID}/~{WorkflowType}/recal_bams" ];then \
			rm -r "~{OutDir}~{SampleID}/~{WorkflowType}/recal_bams"; \
		fi
		if [ -d "~{OutDir}~{SampleID}/~{WorkflowType}/vcfs" ];then \
			rm -r "~{OutDir}~{SampleID}/~{WorkflowType}/vcfs"; \
		fi
		rm ~{sep=" " BamArray}
		rm ~{sep=" " VcfArray}
		# fill-in READMEVCF
		echo "#####MobiDL panelCapture April 2021" > "~{OutDir}~{SampleID}/~{WorkflowType}/README_VCF.txt"
		echo "You will Find several vcf files in the directory, MobiDL using two variant callers:" >> "~{OutDir}~{SampleID}/~{WorkflowType}/README_VCF.txt"
		echo " - SampleID.hc.vcf is the vcf genereated with GATK4 HaplotypeCaller." >> "~{OutDir}~{SampleID}/~{WorkflowType}/README_VCF.txt"
		echo " - SampleID.dv.vcf is the vcf generated with DeepVariant." >> "~{OutDir}~{SampleID}/~{WorkflowType}/README_VCF.txt"
		echo " - SampleID.vcf is the merged VCF containing bot DV and HC variants." >> "~{OutDir}~{SampleID}/~{WorkflowType}/README_VCF.txt"
		echo " - SampleID.vcf.gz is the same VCF as above, but bgzip compressed and tabix indexed (the SampleID.vcf.gz.tbi file)." >> "~{OutDir}~{SampleID}/~{WorkflowType}/README_VCF.txt"
		echo "In the case you want to use the Captain Achab workflow use uncompressed VCF of your choice as input." >> "~{OutDir}~{SampleID}/~{WorkflowType}/README_VCF.txt"
		# fill-in tools version file
		if [ -f ~{CromwellJar} ];then
			echo "----- Execution Engine -----" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "Cromwell: v$(~{JavaExe} -jar ~{CromwellJar} --version | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		if command -v srun &> /dev/null ;then
			echo "----- Workload Manager -----" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "SLURM: v$(srun --version | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File finalFile1 = "~{FinalFile1}"
		File finalFile2 = "~{FinalFile2}"
	}
}
