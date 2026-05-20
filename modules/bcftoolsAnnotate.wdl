version 1.0

task bcftoolsAnnotate {
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
		String BcftoolsExe = "bcftools"
		Boolean Version = false
		# task specific variables
		File VcfFile
		File VcfIndex = "~{VcfFile}.tbi"
		File ReferenceFile
		File ReferenceFileIndex = "~{ReferenceFile}.tbi"
		String col = "ID"
		String VcSuffix
		String VcfExtension = "vcf.gz"
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	# OutPath differs if modules called fsrom dvIdentito or panelCapture
	String OutPath = if WorkflowType == "" then "~{OutDir}" else "~{OutDir}/~{SampleID}/~{WorkflowType}"
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BcftoolsEnv}
		~{BcftoolsExe} annotate \
		-a "~{ReferenceFile}" \
		-c "~{col}" \
		-o "~{OutPath}/~{SampleID}.~{VcSuffix}.~{VcfExtension}" \
		~{VcfFile}
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Bcftools: v$(~{BcftoolsExe} --version | grep bcftools | cut -f2 -d ' ')" >> "~{OutPath}/~{SampleID}.versions.txt";
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File annotatedVcf = "~{OutPath}/~{SampleID}.~{VcSuffix}.~{VcfExtension}"
	}
}
