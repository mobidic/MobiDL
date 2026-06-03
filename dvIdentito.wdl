version 1.0

import "modules/deepVariantCompress.wdl" as runDeepVariant
import "modules/bcftoolsAnnotate.wdl" as runAnnotate
import "modules/identito.wdl" as runIdentito

workflow dvIdentito {
    meta {
        author: "David BAUX"
        email: "david.baux(at)chu-montpellier.fr"
        version: "0.1.0"
        date: "2026-04-27"
    }
    input {
        # variables declarations
        ## conda
        String condaBin
        ## envs
        String singularityEnv
        String bcftoolsEnv
        String samtoolsEnv
        ## queues
        String defQueue
        String avxQueue
        ## resources
        Int cpuHigh
        Int cpuLow
        # Int avxCpu
        Int memoryLow
        Int memoryHigh
        ## Global
        String sampleID
        String outDir
        String workflowType = ""
        String bamInput = ""
        String bamInputIndex = ""
        File refFastaGz
        File intervalBedFile
        File referenceFile
        Boolean version = true
        ## Bioinfo execs
        String bcftoolsExe = "bcftools"
        String csvtkExe = "csvtk"
        String bgZipExe = "bgzip"
        # dv
        String outputMnt
        String dvExe
        String singularityExe
        String dvSimg
        String data
        String refData
        String dvSuffix = "dv"
        String vcSuffix = ".raw"
        String modelType
        ## Identito
        String idList
    }
    File bamFile = if bamInput == "" then "~{outDir}/dvIdentito/~{sampleID}.sorted.bam" else bamInput
    File bamIndex = if bamInputIndex == "" then "~{outDir}/dvIdentito/~{sampleID}.sorted.bam.bai" else bamInputIndex
    # Tasks calls
    call runDeepVariant.deepVariant {
        input:
            Queue = avxQueue,
            CondaBin = condaBin,
            SingularityEnv = singularityEnv,
            SamtoolsEnv = samtoolsEnv,
            Cpu = cpuHigh,
            Memory = memoryLow,
            SampleID = sampleID,
            OutDir = "~{outDir}/dvIdentito",
            WorkflowType = workflowType,            
            DvExe = dvExe,
            SingularityExe = singularityExe,
            BgZipExe = bgZipExe,
            DvSimg = dvSimg,
            BamFile = bamFile,
            BamIndex = bamIndex,
            RefFastaGz = refFastaGz,
            IntervalBedFile = intervalBedFile,
            ModelType = modelType,
            Data = data,
            RefData = refData,
            Output = outputMnt,
            VcSuffix = vcSuffix,
            Version = version
    }
    # to get rsids in dv VCF
    call runAnnotate.bcftoolsAnnotate as annotate {
        input:
            Queue = defQueue,
            CondaBin = condaBin,
            BcftoolsEnv = bcftoolsEnv,
            Cpu = cpuLow,
            Memory = memoryLow,
            SampleID = sampleID,
            OutDir = "~{outDir}/dvIdentito",
            WorkflowType = workflowType,
            ReferenceFile = referenceFile,
            VcfFile = deepVariant.DeepVcfGz,
            VcfIndex = deepVariant.DeepVcfIndex,
            VcSuffix = dvSuffix,
            Version = version
    }
    call runIdentito.identito as identito {
        input:
            Queue = defQueue,
            CondaBin = condaBin,
            BcftoolsEnv = bcftoolsEnv,
            Cpu = cpuLow,
            Memory = memoryLow,
            SampleID = sampleID,
            OutDir = "~{outDir}/dvIdentito",
            WorkflowType = workflowType,
            CsvtkExe = csvtkExe,
            VcfFile = annotate.annotatedVcf,
            IDlist = idList
    }
    output {
        File FinalVcf = identito.outIdent
    }
}