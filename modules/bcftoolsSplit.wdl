version 1.0

task bcftoolsSplit {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-07"
	}
	input {
		# env variables	
		String CondaBin
		String BcftoolsEnv
		# global variables
		String WorkflowType
		Boolean IsPrepared
		String BcftoolsExe
		Boolean Version = false
		String SampleID
		String OutDir
		# task specific variables
		File InputVcf
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{BcftoolsEnv}
		~{BcftoolsExe} norm -m-both \
		-o ~{OutDir}~{SampleID}/~{WorkflowType}/bcftools/~{SampleID}_splitted.vcf ~{InputVcf}
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Bcftools: v$(~{BcftoolsExe} --version | grep bcftools | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
		source ~{CondaBin}deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File outBcfSplit = "~{OutDir}~{SampleID}/~{WorkflowType}/bcftools/~{SampleID}_splitted.vcf"
	}
}

