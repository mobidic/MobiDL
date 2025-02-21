version 1.0

task gatkVariantFiltrationSnp {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-05"
	}
	input {
		# https://gatkforums.broadinstitute.org/gatk/discussion/2806/howto-apply-hard-filters-to-a-call-set
		# https://software.broadinstitute.org/gatk/documentation/article?id=11069
		# global variables
		String SampleID
		String OutDir
		String WorkflowType
		String GatkExe
		File RefFasta
		File RefFai
		File RefDict
		Boolean Version = false
		# task specific variables
		File Vcf
		File VcfIndex
		Int LowCoverage
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
		#	--filter-expression "POLYX > 7.0" --filter-name "HomopolymerRegion" \
	}
	command <<<
		set -e  # To make task stop at 1st error
		~{GatkExe} VariantFiltration \
		-R ~{RefFasta} \
		-V ~{Vcf} \
		--filter-expression "QD < 2.0" --filter-name "LowQualByDepth" \
		--filter-expression "FS > 60.0" --filter-name "FSStrandBias" \
		--filter-expression "MQ < 40.0" --filter-name "LowMappingQuality" \
		--filter-expression "MQRankSum < -3.0" --filter-name "LowMappingQualityRankSum" \
		--filter-expression "ReadPosRankSum < -4.0" --filter-name "LowreadPosRankSum" \
		--filter-expression "SOR > 3.0" --filter-name "SORStrandBias" \
		--filter-expression "DP < ~{LowCoverage}" --filter-name "LowCoverage" \
		-O "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.snp.filtered.vcf"
		if [ ~{Version} = true ];then
			# fill-in tools version file
			echo "GATK: $(~{GatkExe} -version | grep 'GATK' | cut -f6 -d ' ')" >> "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.versions.txt"
		fi
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File filteredSnpVcf = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.snp.filtered.vcf"
		File filteredSnpVcfIndex = "~{OutDir}~{SampleID}/~{WorkflowType}/~{SampleID}.snp.filtered.vcf.idx"
	}
}
