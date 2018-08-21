task phenolyzer {
	Boolean IsPrepared
	String PhenolyzerExe
	String DiseaseFile
	String WorkflowType
	String SampleID
	String OutDir
	String PerlPath
	#runtime attributes
	Int Cpu
	Int Memory
	command <<<
		cd ${PhenolyzerExe}
		${PerlPath} disease_annotation.pl ${DiseaseFile} -f -p -ph -logistic -out ../..${OutDir}${SampleID}/${WorkflowType}/disease/${SampleID}
	>>>
	output {
		String? outPhenolyzer = "${OutDir}${SampleID}/${WorkflowType}/disease/${SampleID}.predicted_gene_scores"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
