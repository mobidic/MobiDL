task compressCramToCrumble {
        #global variables
        String SampleID
        String OutDir
        String WorkflowType
        
        #task specific variables
        File CramFile
	File CramFileIndex
	String CrumbleExe
        #runtime attributes
        Int Cpu
        Int Memory
        command {
                ${CrumbleExe} \
                -I fmt ${CramFile} \
                -O fmt "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.crumble.cram" 
                
        }
        output {
                File crumbleCram = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.crumble.cram"
        }
        runtime {
                cpu: "${Cpu}"
                requested_memory_mb_per_core: "${Memory}"
        }
}
