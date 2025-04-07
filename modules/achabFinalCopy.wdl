version 1.0

task rsyncAchabFiles {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-04-07"
	}
	input {
		# env variables	
		String CondaBin
		String RsyncEnv
		# global variables
		String OutTmpDir
		String OutDir
		String WorkflowType
		String SampleID
		# task specific variables
		String RsyncExe
		Boolean Version = false
		String? OutPhenolyzer
		File OutAchab
		File OutAchabNewHope
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -e  # To make task stop at 1st error
		# TBD put set -e at the beginning of each task to avoid conda deactivate masking errors by returning 0 execution code
		source ~{CondaBin}activate ~{RsyncEnv}
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "Rsync: v$(~{RsyncExe} --version | grep 'rsync' | cut -f3 -d ' ')" >> "~{OutTmpDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
		mkdir -p "~{OutDir}"
		~{RsyncExe} -az --no-g --chmod=ugo=rwX \
		"~{OutTmpDir}/~{SampleID}/~{WorkflowType}/" \
		"~{OutDir}"
		if [ "$?" -eq 0 ];then
			rm -rf "~{OutTmpDir}~{SampleID}"
		fi
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File copiedAchabVersion = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
	}
}
