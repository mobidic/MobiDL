version 1.0

task samtoolsBedCov {
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
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String SamtoolsExe
		Boolean Version = false
		# task specific variables
		File IntervalBedFile
		File BamFile
		File BamIndex
		Int MinCovBamQual
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		source ~{CondaBin}activate ~{SamtoolsEnv}
		~{SamtoolsExe} bedcov -Q ~{MinCovBamQual} \
		~{IntervalBedFile} \
		~{BamFile} \
		> "~{OutDir}/~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_bedcov.bed"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Samtools: v$(~{SamtoolsExe} --version | grep 'samtools' | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		source ~{CondaBin}deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File BedCovFile = "~{OutDir}/~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_bedcov.bed"
	}
}
