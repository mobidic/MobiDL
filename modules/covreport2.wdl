version 1.0

task covReport {
    meta {
        author: "David BAUX"
        email: "d-baux(at)chu-montpellier.fr"
        version: "0.0.1"
        date: "2025-10-15"
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
        String CovReportJar
        String JavaExe
        File BamFile
        File BamIndex
        String GenomeVersion
        File GeneFile        
        # runtime attributes
        String Queue = "hpc"
        Int Cpu
        Int Memory
    }
    String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
    File RefSeqFile = CovReportDir + "/RefSeqExons/RefSeqExon_" + GenomeVersion + ".only_NM.20.txt"
    command <<<
        set -e  # To make task stop at 1st error
        # requires xvfb up and runnning
        xvfb-run "~{JavaExe}" -jar "~{CovReportDir}~{CovReportJar}" -i "~{BamFile}" -r "~{RefSeqFile}" -g "~{GeneFile}" -p "~{SampleID}" -d  "~{OutDir}~{SampleID}/~{WorkflowType}/" -f "~{SampleID}_covreport.pdf" -comments "Exons are assessed including 20bp surrounding the coding sequence based on file ~{GeneFile}"
        # mv "~{CovReportDir}/pdf-results/~{SampleID}_coverage_~{GeneFile}" "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}_covreport.pdf"
        if [ ~{Version} = true ];then
            # fill-in tools version file
            echo "CovReport: v2 rev2092 RefSeq ~{GenomeVersion} + 20bp" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
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
