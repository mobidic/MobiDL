version 1.0

task bcftoolsNorm {
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
		File SortedVcf
		String VcSuffix
		String VcfExtension = "vcf"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{BcftoolsEnv}
		~{BcftoolsExe} norm -O v -m -both \
		-o "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}" \
		~{SortedVcf}
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
		File normVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}"
	}
}
