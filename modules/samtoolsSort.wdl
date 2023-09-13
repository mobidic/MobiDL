version 1.0

task samtoolsSort {
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
		String BamFile
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		source ~{CondaBin}activate ~{SamtoolsEnv}
		${SamtoolsExe} sort -@ ${Cpu} -l 6 \
		-o "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${BamFile}"
		mv "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.sorted.bam" \
		"${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.bam"
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
		File sortedBam = "${OutDir}${OutputDirSampleID}/${WorkflowType}/${SampleID}.bam"
	}
}
