
task deepVariant {

	#definition of variables
	String SampleID
	String OutDir
	String WorkflowType

	String ReferenceFasta
	#File RefFai
	File BamFile
	#File BamIndex
	String BedFile
	
	String ModelType

	String Data
	String RefData
	String DvOut
	
	String Output
	String DeepExe

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
		--output_vcf="${DvOut}/${SampleID}/${WorkflowType}/${SampleID}.vcf"
	}


	output{
		 File DeepVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.vcf"
	}


	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}

}
