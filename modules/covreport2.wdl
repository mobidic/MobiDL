version 1.0

task covReport {
    meta {
        author: "David BAUX"
        email: "d-baux(at)chu-montpellier.fr"
        version: "0.0.1"
        date: "2025-09-05"
    }
    input {
        # global variables
        String SampleID
        String OutDir
        String OutDirSampleID = ""        
        String WorkflowType
        Boolean Version = true
        # task specific variables
        String CovReportDir
        File CovReportJar
        File JavaExe
        File BamFile
        File BamIndex
        String GenomeVersion
        File GeneFile        
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
    File RefSeqFile = CovReportDir + "/RefSeqExons/RefSeqExon_" + GenomeVersion + ".txt"
    command <<<
        set -e  # To make task stop at 1st error
        "~{JavaExe}" -jar "~{CovReportDir}~{CovReportJar}" -i "~{BamFile}" -r "~{RefSeqFile}" -g "~{GeneFile}" -p "~{SampleID}"
        mv "~{CovReportDir}/pdf-results/~{SampleID}_coverage_~{GeneFile}" "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}_covreport.pdf"
        if [ ~{Version} = true ];then
            # fill-in tools version file
            echo "CovReport: v2 rev2092 " >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
        fi
    >>>
    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
    output {
        File crumbled = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}_covreport.pdf"
    }
}
