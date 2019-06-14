task refCallFiltration {
        #global variables
        String SampleID
        String OutDir
        String WorkflowType
        

        #task specific variables
        File VcfToRefCalled
	String VcftoolsExe 
        
        #runtime attributes
        Int Cpu
        Int Memory

        command {
                 ${VcftoolsExe} --vcf ${VcfToRefCalled} \
                 --remove-filtered "RefCall" \
                 --recode --out "${OutDir}${SampleID}/${WorkflowType}/${SampleID}"  \
                
        }
        output {
                File noRefCalledVcf = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.recode.vcf"
                #File refcalledLog = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.log"
        }
        runtime {
                cpu: "${Cpu}"
                requested_memory_mb_per_core: "${Memory}"

	}
}
