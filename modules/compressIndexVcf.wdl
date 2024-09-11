version 1.0

task compressIndexVcf {
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
		String WorkflowType
		String BgZipExe
		String TabixExe
		Boolean Version = false
		# task specific variables
		File VcfFile
		String VcSuffix
		String VcfExtension = "vcf"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{SamtoolsEnv}
		~{BgZipExe} -c \
		~{VcfFile} \
		> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}.gz"
		~{TabixExe} -fp vcf \
		"~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}.gz"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Bgzip: v$(~{BgZipExe} --version 2>&1 | grep 'bgzip' | cut -f3 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
			echo "Tabix: v$(~{TabixExe} --version 2>&1 | grep 'tabix' | cut -f3 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File bgZippedVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}.gz"
		File bgZippedVcfIndex = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}~{VcSuffix}.~{VcfExtension}.gz.tbi"
	}
}
