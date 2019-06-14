task rtgMerge {
        #global variables
        String SampleID
        String OutDir
        String WorkflowType
	String VcfSuffix
       
        
        #task specific variables
        Array[File] VcfFiles
	String RtgExe
        
        #runtime attributes
        Int Cpu
        Int Memory
        command {
                 ${RtgExe} \
                 
                -I ${VcfFiles} \
                -o "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}_rtg.vcf.gz" \
                --force-merge-all
        }
        output {
                File rtgMergedVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}_rtg.vcf.gz"
                File rtgMergedVcfIndex = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}${VcfSuffix}_rtg.vcf.gz.tbi"
        }
        runtime {
                cpu: "${Cpu}"
                requested_memory_mb_per_core: "${Memory}"
        }
}
