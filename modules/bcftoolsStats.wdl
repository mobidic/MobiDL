version 1.0

task bcftoolsStats {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables	
		String CondaBin
		String BcftoolsEnv
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String BcftoolsExe
		Boolean Version = false
		# task specific variables
		File VcfFile
		File VcfFileIndex
		String VcSuffix
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BcftoolsEnv}
		~{BcftoolsExe} stats \
		~{VcfFile} \
		> "~{OutDir}~{SampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}~{VcSuffix}.stats.txt"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Bcftools: v$(~{BcftoolsExe} --version | grep bcftools | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File statVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/PicardQualityDir/~{SampleID}~{VcSuffix}.stats.txt"
	}
}
