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
	String DvExe
	String GatkExe
	Int Cpu
	Int Memory
	String SingularityExe
	String DvSimg
	command{
		${SingularityExe} run \
		--bind ${Output} \
		--bind ${RefData} \
		--bind ${Data} \
		${DvSimg}	${DvExe} \
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
	}
	output{
		 File DeepVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcSuffix}.vcf"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}
