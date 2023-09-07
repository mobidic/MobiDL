version 1.0

task sambambaIndex {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables	
		String CondaBin
		String SambambaEnv
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String SambambaExe
		Boolean Version = false
		# task specific variables
		File BamFile
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		source ~{CondaBin}activate ~{SambambaEnv}
		~{SambambaExe} index -t ~{Cpu} \
		~{BamFile} \
		"~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.bam.bai"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Sambamba: v$(~{SambambaExe} --version 2>&1 | grep 'sambamba' | cut -f2 -d ' ' | uniq)" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "----- Variant Calling -----" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		source ~{CondaBin}deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File bamIndex = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}.bam.bai"
	}
}
