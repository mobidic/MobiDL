version 1.0

task achabDirPreparation {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-07"
	}
	input {
		# global variables
		String WorkflowType
		String SampleID
		String OutDir
		Boolean Version = false
		# task specific variables
		File InputVcf
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		if [ ! -d "~{OutDir}" ];then \
			mkdir -p "~{OutDir}"; \
		fi
		if [ ! -d "~{OutDir}~{SampleID}" ];then \
			mkdir "~{OutDir}~{SampleID}"; \
		fi
		if [ ! -d "~{OutDir}~{SampleID}/~{WorkflowType}" ];then \
			mkdir "~{OutDir}~{SampleID}/~{WorkflowType}"; \
		fi
		if [ ! -d "~{OutDir}~{SampleID}/~{WorkflowType}/disease" ];then \
			mkdir "~{OutDir}~{SampleID}/~{WorkflowType}/disease"; \
		fi
		if [ ! -d "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel" ];then \
			mkdir "~{OutDir}~{SampleID}/~{WorkflowType}/achab_excel"; \
		fi
		if [ ! -d "~{OutDir}~{SampleID}/~{WorkflowType}/bcftools" ];then \
			mkdir "~{OutDir}~{SampleID}/~{WorkflowType}/bcftools"; \
		fi
		cp "~{InputVcf}" "~{OutDir}~{SampleID}/~{WorkflowType}"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "----- Annotation -----" > "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outDir = "~{OutDir}"
		File sampleDir = "~{OutDir}~{SampleID}"
		File workflowTypeDir = "~{OutDir}~{SampleID}/~{WorkflowType}"
		Boolean isPrepared = true
	}
}
