task deepVariant {
	#definition of variables
	String SampleID
	String OutDir
	String WorkflowType
	String ReferenceFasta
	#File RefFai
	File BamFile
	File BamIndex
	String BedFile
	String ModelType
	String Data
	String RefData
	String DvOut
	String Output
	String VcSuffix
	String DeepExe
	String GatkExe
	Int Cpu
	Int Memory
	String Singularity
	String SingularityImg
	command{
		${Singularity} run \
		--bind ${Output} \
		--bind ${RefData} \
		--bind ${Data} \
		${SingularityImg}	${DeepExe} \
		--model_type=${ModelType} \
		--ref=${ReferenceFasta} \
		--reads="${DvOut}/${SampleID}/${WorkflowType}/${SampleID}.bam" \
		--regions=${BedFile} \
		--num_shards=${Cpu} \
		--output_vcf="${DvOut}/${SampleID}/${WorkflowType}/${SampleID}.unsorted.vcf"
		${GatkExe} SortVcf \
		-I "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.unsorted.vcf" \
		-O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dv.vcf"
		rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.unsorted.vcf" "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.dv.vcf.idx"
		mv "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.unsorted.visual_report.html" "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.unsorted.dv.html"
		# ${GatkExe} RenameSampleInVcf \
		# -I "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sampletorename2.vcf" \
		# -O "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.raw.vcf" \
		# --NEW_SAMPLE_NAME "${SampleID}.dv" \
		# --OLD_SAMPLE_NAME "${SampleID}"
		# rm "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sampletorename.vcf" "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sampletorename2.vcf" "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.sampletorename2.vcf.idx"
	}
	output{
		 File DeepVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
