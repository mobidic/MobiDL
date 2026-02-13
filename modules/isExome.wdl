version 1.0

task isExome {
    meta {
        author: "David BAUX"
        email: "d-baux(at)chu-montpellier.fr"
        version: "0.1.0"
        date: "2026-02-13"
    }

    input {
        # task specific variables
        String IntervalBedFile
        # runtime attributes
        String Queue
        Int Cpu
        Int Memory
    }
    command <<<
        set -e
        if [[ "~{IntervalBedFile}" =~ [Ee]xome ]];then
            echo "true"
        else
            echo "false"
        fi
    >>>
    runtime {
        queue: "~{Queue}"
        cpu: "~{Cpu}"
        requested_memory_mb_per_core: "~{Memory}"
    }
    output {
        Boolean isExomeBool = read_boolean(stdout())
    }
}