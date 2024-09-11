version 1.0

task samtoolsCramIndex {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables
		String CondaBin
		String SamtoolsEnv
		# global variables
		String SampleID
		String OutDir
		String OutDirSampleID = ""
		String WorkflowType
		String SamtoolsExe
		Boolean Version = false
		# task specific variables
		File CramFile
		String CramSuffix
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
 	command <<<
		source ~{CondaBin}activate ~{SamtoolsEnv}
		~{SamtoolsExe} index \
		~{CramFile} \
		"~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}~{CramSuffix}.cram.crai"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Samtools: v$(~{SamtoolsExe} --version | grep 'samtools' | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File cramIndex = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/~{SampleID}~{CramSuffix}.cram.crai"
	}
}
