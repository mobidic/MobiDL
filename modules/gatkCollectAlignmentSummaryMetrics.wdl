task gatkCollectAlignmentSummaryMetrics {
	#https://software.broadinstitute.org/gatk/documentation/tooldocs/current/picard_analysis_CollectAlignmentSummaryMetrics.php
	#global variables
	String SrunLow
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	File RefFasta
	#task specific variables
	File BamFile
	command {
		${SrunLow} ${GatkExe} CollectAlignmentSummaryMetrics \
		-R ${RefFasta} \
		-I ${BamFile} \
		-O "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_alignment_summary.txt"
	}
	output {
		File alignmentSummary = "${OutDir}${SampleID}/${WorkflowType}/PicardQualityDir/${SampleID}_alignment_summary.txt"
	}
}