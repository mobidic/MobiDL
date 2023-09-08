task qualimapBamQc {
	#see http://qualimap.bioinfo.cipf.es/doc_html/faq.html#command-line if X11 error
	#global variables
	String SampleID
 	String OutDir
	String WorkflowType
	String QualimapExe
	#task specific variables
	File IntervalBedFile
	File BamFile
	#runtime attributes
	Int Cpu
	Int Memory
	command <<<
		${QualimapExe} bamqc --java-mem-size=${Memory}M -bam ${BamFile} \
		-outdir "${OutDir}${SampleID}/${WorkflowType}/qualimap" \
		-c \
		--feature-file ${IntervalBedFile} \
		-nt ${Cpu} \
		-sd
	>>>
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
