version 1.0

task jvarkitVcfPolyX {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String JavaExe
		String VcfPolyXJar
		File RefFasta
		File RefFai
		File RefDict
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
		~{JavaExe} -jar ~{VcfPolyXJar} vcfpolyx \
		-R ~{RefFasta} \
		-o "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.polyx.vcf" \
		"~{Vcf}"
		#just cp index file suppose no changes
		cp ~{VcfIndex} "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.polyx.vcf.idx"
		if [ ~{Version} = true ];then
			echo "VcfPolyX: $(~{JavaExe} -jar ~{VcfPolyXJar} --version)" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt";
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File polyxedVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.polyx.vcf"
		File polyxedVcfIndex = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.polyx.vcf.idx"
	}
}
