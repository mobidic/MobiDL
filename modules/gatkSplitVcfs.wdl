version 1.0

task gatkSplitVcfs {
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
		String GatkExe
		Boolean Version = false
		# task specific variables
		File Vcf
		File VcfIndex
		String VcSuffix
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		export LANG=en_US.UTF-8
		export LC_ALL=en_US.UTF-8
		export LC_TIME=en_US.UTF-8     # ensure english date format
		~{GatkExe} SplitVcfs \
		-I ~{Vcf} \
		--SNP_OUTPUT "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.snp.vcf" \
		--INDEL_OUTPUT "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.indel.vcf" \
		--STRICT false
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "GATK: $(~{GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File snpVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.snp.vcf"
		File snpVcfIndex = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.snp.vcf.idx"
		File indelVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.indel.vcf"
		File indelVcfIndex = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.indel.vcf.idx"
	}
}
