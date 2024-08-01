version 1.0

task bcftoolsLeftAlign {
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
		String OutDir
		String SampleID
		String BcftoolsExe
		Boolean Version = false
		# task specific variables
		File FastaGenome
		File FastaGenomeFai = "~{FastaGenome}.fai"
		File SplittedVcf
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{BcftoolsEnv}
		~{BcftoolsExe} norm -f ~{FastaGenome} \
		-o ~{OutDir}~{SampleID}/~{WorkflowType}/bcftools/~{SampleID}_leftalign.vcf ~{SplittedVcf}
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
		File outBcfLeftAlign = "~{OutDir}~{SampleID}/~{WorkflowType}/bcftools/~{SampleID}_leftalign.vcf"
	}
}
