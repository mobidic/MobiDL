version 1.0

task multiqc {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.2"
		date: "2023-09-05"
	}
	input {
		# env variables	
		String CondaBin
		String MultiqcEnv
		# global variables
		String SampleID
		String Name = SampleID  # Name of MQC report
		String OutDir
		String WorkflowType
		String MultiqcExe
		String perlExe = "/usr/bin/perl"
		String GatkExe
		Boolean Version = false
		# task specific variables
		File? Vcf
		File? configFile  # If provided, run ONLY 'custom' metrix
		#runtime attributes
		Array[String] TaskOut  # To force exec after given tasks
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "----- Quality -----" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "GATK (Picard): $(~{GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		source ~{CondaBin}activate ~{MultiqcEnv}
		~{MultiqcExe} ~{"--module custom_content --config " + configFile} -o "~{OutDir}~{SampleID}/~{WorkflowType}/" -n "~{Name}_multiqc" "~{OutDir}~{SampleID}/~{WorkflowType}/" -f
		~{perlExe} -pi.bak -e 's/NaN/null/g' "~{OutDir}~{SampleID}/~{WorkflowType}/~{Name}_multiqc_data/multiqc_data.json"
		if [ ~{Version} = true ];then
			echo "MultiQC: v$(~{MultiqcExe} --version | grep 'multiqc' | cut -f3 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File multiqcHtml = "~{OutDir}~{SampleID}/~{WorkflowType}/~{Name}_multiqc.html"
	}
}
