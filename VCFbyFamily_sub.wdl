version 1.0


workflow PedToVCF {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.0.7"
        date: "2025-03-11"
    }

    input {
        File pedFile
        String analysisDir  # Eg. /path/to/runID/MobiDL
        String? outputPath  # Default = send to 'AnalysisDir/byFamily/casIndex/casIndex.(merged.)vcf'

        String wdl = "panelCapture"
        String suffixVcf = ".hc.vcf"

        String condaBin

        # PedToFam task:
        String pedsEnv  # Any python env with 'peds' package installed
        File? scriptExe
        # mergeVCF task:
        String bcftoolsEnv
    }

    call pedToFam {
        input:
            PedFile = pedFile,
            CondaBin = condaBin,
            PedsEnv = pedsEnv,
            PathExe = scriptExe
    }

    scatter (aStatus in pedToFam.status) {
        String aCasIndex=aStatus[0]
        String byFamDir = if defined(outputPath) then outputPath + "/byFamily/" + aCasIndex + "/" else analysisDir + "/byFamily/" + aCasIndex + "/"

        call mergeVCF {
            input:
                CasIndex = aCasIndex,
                Family = aStatus[1],
                PrefixPath = analysisDir,
                VcfOutPath = byFamDir,
                WDL = wdl,
                SuffixVcf = suffixVcf,
                CondaBin = condaBin,
                BcftoolsEnv = bcftoolsEnv
        }
    }

    output {
        Array[File] mergedVCFs = mergeVCF.vcfOut
    }
}


task pedToFam {
    input {
        File PedFile
        String PythonExe = "python3"
        File PathExe = "ped_to_fam.py"

        String CondaBin
        String PedsEnv  # Any python env with 'peds' package installed
        Int Cpu = 1
        Int Memory = 768
    }

    command <<<
        set -e

        source ~{CondaBin}activate ~{PedsEnv}
        "~{PythonExe}" "~{PathExe}" "~{PedFile}"
        conda deactivate
    >>>

    output {
        Array[Array[String]] status = read_json("status.json")  # [casIndex, membersList, father, mother, affectedList]
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}


task mergeVCF {
    input {
        String Family  # Eg.: 'casIndex,father,mother'
        String CasIndex
        String PrefixPath  # Eg: /path/to/runID/MobiDL/
        String VcfOutPath  # Eg: /path/to/runID/MobiDL/byFam/aSample/
        String WDL = "panelCapture"
        String SuffixVcf = ".HC.vcf"

        String CondaBin
        String BcftoolsEnv
        String BcftoolsExe = "bcftools"
        Int Cpu = 1
        Int Memory = 768
    }

    String VcfOut = VcfOutPath + CasIndex + ".vcf"

    command <<<
        set -e

        if [[ ! -d ~{VcfOutPath} ]]; then
            mkdir --parents ~{VcfOutPath}
        fi

        # If family has 1 single sample -> simply copy VCF
        if [ "$(echo ~{Family} | tr "," "\n" | wc -l)" -eq "1" ] ; then
            memb=~{Family}
            cp --verbose "~{PrefixPath}/${memb}/~{WDL}/${memb}~{SuffixVcf}" "~{VcfOut}"

        else
            source ~{CondaBin}activate ~{BcftoolsEnv}

            for memb in $(echo ~{Family} | tr "," " ") ; do
                ls -d "~{PrefixPath}/${memb}/~{WDL}/${memb}~{SuffixVcf}"
            done |
                xargs ~{BcftoolsExe} merge \
                                            --merge none \
                                            --missing-to-ref \
                                            --no-index \
                                            -Ov -o "~{VcfOut}"

            conda deactivate
        fi
    >>>

    output {
        File vcfOut = VcfOut
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
