task qualimapBamQc {
	#see http://qualimap.bioinfo.cipf.es/doc_html/faq.html#command-line if X11 error
	#global variables
	String SrunHigh
	Int Threads
	Int JavaRam
	String SampleID	
	String OutDir
	String WorkflowType
	String QualimapExe
	#task specific variables
	File IntervalBedFile
	File BamFile
	command <<<
		${SrunHigh} ${QualimapExe} bamqc --java-mem-size=${JavaRam}G -bam ${BamFile} \
		-outdir "${OutDir}${SampleID}/${WorkflowType}/qualimap" \
		-c \
		--feature-file ${IntervalBedFile} \
		-nt ${Threads} \
		-sd
	>>>
}