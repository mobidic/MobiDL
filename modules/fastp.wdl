version 1.0

task fastp {
    meta {
        author: "David BAUX"
        email: "d-baux(at)chu-montpellier.fr"
        version: "0.0.1"
        date: "2023-09-01"
    }
    input {
        # env variables    
        String CondaBin
        String FastpEnv
        # global variables
        String SampleID
        String OutDirSampleID = ""
        String OutDir
        String WorkflowType
        String FastpExe
        Boolean Version
        # task specific variables
        File FastqR1
        File FastqR2
        String Suffix1
        String Suffix2
        Boolean DirsPrepared
        String NoFiltering
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
    command <<<
        set -e  # To make task stop at 1st error
        source ~{CondaBin}activate ~{FastpEnv}
        ~{FastpExe} -w ~{Cpu} ~{NoFiltering} \
        -i ~{FastqR1} \
        -I ~{FastqR2} \
        -o "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}~{Suffix1}.fastp.fq.gz" \
        -O "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}~{Suffix2}.fastp.fq.gz" \
        -R "~{SampleID}" \
        -j "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}_fastp.json" \
        -h "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}_fastp.html"
        if [ ~{Version} = true ];then
            # fill-in tools version file
            echo "fastp: v$(~{FastpExe} --version 2>&1 | cut -f2 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
        fi
        conda deactivate
    >>>
    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
    output {
        File fastpR1 = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}~{Suffix1}.fastp.fq.gz"
        File fastpR2 = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}~{Suffix2}.fastp.fq.gz"
        File fastpJson = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}_fastp.json"
        File fastpHtml = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/FastpDir/~{SampleID}_fastp.html"
    }
}
