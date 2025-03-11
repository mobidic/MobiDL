version 1.0


workflow PedToVCF {
    input {
        File PedFile
        String AnalysisDir  # Eg. /path/to/runID/MobiDL
    }


    call pedToFam {
        input:
            pedFile = PedFile
    }

    scatter (Family in pedToFam.families) {
        call mergeVCF{
            input:
                family = Family,
                prefixPath = AnalysisDir
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
        String pathExe = "ped_to_fam.py"

        Int Cpu = 1
        Int Memory = 768
    }

    command <<<
        set -euo pipefail

        "~{pythonExe}" "~{pathExe}" "~{pedFile}"
    >>>

    output {
        Array[Array[String]] families = read_json("families.json")
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}


task mergeVCF {
    meta {
        author: "Felix VANDERMEEREN"
        email: "felix.vandermeeren(at)chu-montpellier.fr"
        version: "0.0.3"
        date: "2025-03-11"
    }

    input {
        Array[String] family
        String prefixPath  # Eg: /path/to/runID/MobiDL
        String WDL = "panelCapture"
        String suffixVcf = ".HC.vcf"
        String bcftoolsExe = "bcftools"
        String? outputPath

        Int Cpu = 1
        Int Memory = 768
    }

    String VcfOutPath = if defined(outputPath) then outputPath + "/byFamily/" + family[0] + "/" else prefixPath + "/byFamily/" + family[0] + "/"
    String VcfOut = VcfOutPath + family[0] + ".vcf"

    command <<<
        set -euo pipefail

        if [[ ! -d ~{VcfOutPath} ]]; then
            mkdir --parents ~{VcfOutPath}
        fi

        casIndex=$(echo ~{sep="," family} | cut -d"," -f1)

        for memb in ~{sep=" " family} ; do
            ls -d "~{prefixPath}/${memb}/~{WDL}/${memb}~{suffixVcf}"
        done |
            xargs ~{bcftoolsExe} merge \
                                        --merge none \
                                        --missing-to-ref \
                                        --no-index \
                                        -Ov -o "~{VcfOut}"
    >>>

    output {
        File vcfOut = VcfOut
    }

    runtime {
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
}
