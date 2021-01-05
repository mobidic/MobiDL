task toolVersions {
	String SampleID
	String OutDir
	String WorkflowType
    String GenomeVersion
    String FastqcExe
    String BwaExe
    String SamtoolsExe
    String SambambaExe
    String BedToolsExe
    String QualimapExe
    String BcfToolsExe
    String BgZipExe
    String CrumbleExe
    String TabixExe
    String MultiqcExe 
    String GatkExe
    String JavaExe
    String VcfPolyXJar
	#runtime attributes
	Int Cpu
	Int Memory
    String dollar = "$"
	command {
        date > "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Sample ID: ${SampleID}" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Workflow: MobiDL ${WorkflowType}" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Genome Version: ${GenomeVersion}" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "----- Alignment -----" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "BWA: ${dollar}(${BwaExe} 2>&1 | grep 'Version' | cut -f2 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Samtools: ${dollar}(${SamtoolsExe} --version | grep 'samtools' | cut -f2 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Sambamba: ${dollar}(${SambambaExe} --version 2>&1 | grep 'sambamba 0' | cut -f2 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "GATK: ${dollar}(${GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"        
        echo "----- Variant Calling -----" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "GATK Haplotype Caller: ${dollar}(${GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "DeepVariant: 0.10" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "VcfPolyX: ${dollar}(${JavaExe} -jar ${VcfPolyXJar} --version)" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Bcftools: ${dollar}(${BcfToolsExe} --version | grep bcftools | cut -f2 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "----- Compression -----" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Crumble: ${dollar}(${CrumbleExe} -h | grep 'Crumble' | cut -f3 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Bgzip: ${dollar}(${BgZipExe} --version 2>&1 | grep 'bgzip' | cut -f3 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Tabix: ${dollar}(${TabixExe} --version 2>&1 | grep 'tabix' | cut -f3 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "----- Quality -----" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "FastQC: ${dollar}(${FastqcExe} -v | grep 'FastQC' | cut -f2 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "Qualimap: ${dollar}(${QualimapExe} -h | grep 'QualiMap' | cut -f2 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "GATK (Picard): ${dollar}(${GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
        echo "MultiQC: ${dollar}(${MultiqcExe} --version | grep 'multiqc' | cut -f3 -d ' ')" >> "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
	}
	output {
		File versionFile = "${OutDir}${SampleID}/${WorkflowType}/${SampleID}.versions.txt"
	}
	runtime {
		cpu: "${Cpu}"
		requested_memory_mb_per_core: "${Memory}"
	}
}