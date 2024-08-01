task gatkHaplotypeCaller {
	# global variables
	String SampleID
	String OutDir
	String WorkflowType
	String GatkExe
	File RefFasta
	File RefFai
	File RefDict
	File DbSNP
	File DbSNPIndex
	## task specific variables
	File GatkInterval
	String IntervalName = basename("${GatkInterval}", ".intervals")
	File BamFile
	File BamIndex
	Int MaxMNPDist = 0
	# when callcaching on, seem to keep Bam and index in the same directory for HC execution
	# does not work in fine...
	# Pair[File, File] Bam = (BamFile, BamIndex)
	String SwMode
	String EmitRefConfidence
	# runtime attributes
	Int Cpu
	Int Memory
	command {
		${GatkExe} HaplotypeCaller \
		-R ${RefFasta} \
		-I ${BamFile} \
		-L ${GatkInterval} \
		--dbsnp ${DbSNP} \
		--smith-waterman ${SwMode} \
		--emit-ref-confidence ${EmitRefConfidence} \
		--max-mnp-distance ${MaxMNPDist} \
		-O "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${IntervalName}.hc.vcf"
		# ${GatkExe} RenameSampleInVcf \
		# -I "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${IntervalName}.sampletorename.vcf" \
		# -O "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${IntervalName}.vcf" \
		# --NEW_SAMPLE_NAME "${SampleID}.hc" \
		# --OLD_SAMPLE_NAME "${SampleID}"
		# rm "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${IntervalName}.sampletorename.vcf"
	}
	output {
		File hcVcf = "${OutDir}${SampleID}/${WorkflowType}/vcfs/${SampleID}.${IntervalName}.hc.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
