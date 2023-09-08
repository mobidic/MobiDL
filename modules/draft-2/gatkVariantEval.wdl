task gatkVariantEval {
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String GatkExe
	#task specific variables
	String VcSuffix
	String VariantEvalEV
	File VcfFile
	File RefFasta
	File RefFai
	File RefDict
	File DbSNP
	File DbSNPIndex
	#runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} IndexFeatureFile \
		-F ${VcfFile}
		touch "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}${VcSuffix}_VariantEval.grp"
		${GatkExe} VariantEval \
		-R ${RefFasta} \
		--eval ${VcfFile} \
		-EV ${VariantEvalEV} \
		-D ${DbSNP} \
		-no-ev \
		-O "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}${VcSuffix}_VariantEval.grp"
	}
	output {
		File VEgrp = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}${VcSuffix}_VariantEval.grp"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}