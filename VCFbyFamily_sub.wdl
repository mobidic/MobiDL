version 1.0


workflow PedToVCF {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.0.5"
        date: "2025-03-11"
    }

    input {
        File PedFile
        String AnalysisDir  # Eg. /path/to/runID/MobiDL
        String? OutputPath  # Default = send to 'AnalysisDir/byFamily/casIndex/casIndex.(merged.)vcf'

        String WDL = "panelCapture"
        String SuffixVcf = ".hc.vcf"

        String condaBin

        # PedToFam task:
        String pedsEnv  # Any python env with 'peds' package installed
        File? scriptExe
        # mergeVCF task:
        String bcftoolsEnv
    }


    call pedToFam {
        input:
            pedFile = PedFile,
            CondaBin = condaBin,
            PedsEnv = pedsEnv,
            pathExe = scriptExe
    }

    scatter (aStatus in pedToFam.status) {
        call mergeVCF {
            input:
                casIndex = aStatus[0],
                family = aStatus[1],
                prefixPath = AnalysisDir,
                outputPath = OutputPath,
                wdl = WDL,
                suffixVcf = SuffixVcf,
                CondaBin = condaBin,
                BcftoolsEnv = bcftoolsEnv
        }
    }

    output{
        Array[File] mergedVCFs = mergeVCF.vcfOut
    }
}


task pedToFam {
    input {
        File pedFile
        String pythonExe = "python3"
        File pathExe = "ped_to_fam.py"

        String CondaBin
        String PedsEnv  # Any python env with 'peds' package installed
        Int Cpu = 1
        Int Memory = 768
    }

    command <<<
        set -euo pipefail

        source ~{CondaBin}activate ~{PedsEnv}
        "~{pythonExe}" "~{pathExe}" "~{pedFile}"
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
        String family  # Eg.: 'casIndex,father,mother'
        String casIndex
        String prefixPath  # Eg: /path/to/runID/MobiDL
        String wdl = "panelCapture"
        String suffixVcf = ".HC.vcf"
        String? outputPath

        String CondaBin
        String BcftoolsEnv
        String bcftoolsExe = "bcftools"
        Int Cpu = 1
        Int Memory = 768
    }

    String VcfOutPath = if defined(outputPath) then outputPath + "/byFamily/" + casIndex + "/" else prefixPath + "/byFamily/" + casIndex + "/"
    String VcfOut = VcfOutPath + casIndex + ".vcf"

    command <<<
        set -euo pipefail
        set -x

        if [[ ! -d ~{VcfOutPath} ]]; then
            mkdir --parents ~{VcfOutPath}
        fi

        # If family has 1 single sample -> simply copy VCF
        if [ "$(echo ~{family} | tr "," "\n" | wc -l)" -eq "1" ] ; then
            memb=~{family}
            cp --verbose "~{prefixPath}/${memb}/~{wdl}/${memb}~{suffixVcf}" "~{VcfOut}"

        else
            set +x; source ~{CondaBin}activate ~{BcftoolsEnv}; set -x

            for memb in $(echo ~{family} | tr "," " ") ; do
                ls -d "~{prefixPath}/${memb}/~{wdl}/${memb}~{suffixVcf}"
            done |
                xargs ~{bcftoolsExe} merge \
                                            --merge none \
                                            --missing-to-ref \
                                            --no-index \
                                            -Ov -o "~{VcfOut}"

            set +x; conda deactivate
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
