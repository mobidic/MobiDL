version 1.0

task phenolyzer {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-07"
	}
	input {
		# env variables	
		String CondaBin
		String AchabEnv
		# global variables		
		String DiseaseFile
		String WorkflowType
		String SampleID
		String OutDir
		Boolean Version = false
		# task specific variables
		Boolean IsPrepared
		String PhenolyzerExe
		String PerlPath
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		source ~{CondaBin}activate ~{AchabEnv}
		cd "~{PhenolyzerExe}"
		echo "$(pwd)"
		~{PerlPath} disease_annotation.pl \
		"~{DiseaseFile}" -f -p -ph -logistic \
		-d "~{PhenolyzerExe}/lib/compiled_database" \
		-out "~{OutDir}~{SampleID}/~{WorkflowType}/disease/~{SampleID}"
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		String outPhenolyzer = "~{OutDir}~{SampleID}/~{WorkflowType}/disease/~{SampleID}.predicted_gene_scores"
	}
}
