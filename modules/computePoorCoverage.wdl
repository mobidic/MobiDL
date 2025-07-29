version 1.0

task computeGenomecov {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables	
		String CondaBin
		String BedtoolsEnv
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String GenomeVersion
		String BedToolsExe
		String AwkExe
		String SortExe
		Boolean Version = false
		# task specific variables
		File IntervalBedFile
		Int BedtoolsLowCoverage
		File BamFile
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	String OutputFile = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_genomecov.tsv"
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BedtoolsEnv}
		~{BedToolsExe} genomecov -ibam ~{BamFile} -bga \
		| ~{AwkExe} -v low_coverage="~{BedtoolsLowCoverage}" '$4<low_coverage' \
		| ~{BedToolsExe} intersect -wb -a ~{IntervalBedFile} -b - \
		> "~{OutputFile}"
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File genomecovFile = OutputFile
	}
}

task computePoorCoverage {
	meta {
		author: "David BAUX"
		email: "d-baux(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2023-09-04"
	}
	input {
		# env variables	
		String CondaBin
		String BedtoolsEnv
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String GenomeVersion
		String BedToolsExe
		String AwkExe
		String SortExe
		Boolean Version = false
		# task specific variables
		File GenomecovFile
		Int BedToolsSmallInterval
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BedtoolsEnv}
		~{SortExe} -k1,1 -k2,2n -k3,3n "~{GenomecovFile}" \
		| ~{BedToolsExe} merge -c 4 -o distinct -i - \
		| ~{AwkExe} -v small_intervall="~{BedToolsSmallInterval}" \
		'BEGIN {OFS="\t";print "#chr","start","end","region","size bp","type","UCSC link"} {a=($3-$2+1);if(a<small_intervall) {b="SMALL_INTERVAL"} else {b="OTHER"};url="http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db='~{GenomeVersion}'&position="$1":"$2-10"-"$3+10"&highlight='~{GenomeVersion}'."$1":"$2"-"$3;print $0, a, b, url}' \
		> "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_poor_coverage.tsv"
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File poorCoverageFile = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_poor_coverage.tsv"
	}
}

task computePoorCovExtended {
	meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2025-05-26"
	}
	input {
		# env variables	
		String CondaBin
		String BedtoolsEnv
		# global variables
		String SampleID
		String OutDirSampleID = ""
		String OutDir
		String WorkflowType
		String GenomeVersion
		String BedToolsExe
		String AwkExe
		String SortExe
		Boolean Version = false
		# task specific variables
		Int BedToolsSmallInterval	
		File GenomecovFile
		File CoverageFile
		String? PoorCoverageFileFolder
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	String OutputFile = "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/coverage/~{SampleID}_poorCoverage_extended.tsv"
	command <<<
		set -e  # To make task stop at 1st error
		source ~{CondaBin}activate ~{BedtoolsEnv}
		~{SortExe} -k1,1 -k2,2n -k3,3n "~{GenomecovFile}" \
		| ~{BedToolsExe} merge -d 1 -c 4,10,10 -o distinct,min,max -i - \
		| ~{BedToolsExe} intersect -loj -c -a - -b ~{PoorCoverageFileFolder}/*.tsv  \
		| ~{BedToolsExe} intersect -wb -loj -a - -b ~{CoverageFile}  \
		| awk -v small_intervall="~{BedToolsSmallInterval}" -v GenomeVersion="~{GenomeVersion}" \
		'BEGIN {OFS="\t";print "#chr","start","end","gene","region","region_size","type","MIN_COV","MAX_COV","Occurrence","ROI_MEAN_COV","UCSC link"} {split($4,gene,":");a=($3-$2+1);if(a<small_intervall) {b="SMALL_INTERVAL"} else {b="OTHER"};url="http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db='GenomeVersion'&position="$1":"$2-10"-"$3+10"&highlight='GenomeVersion'."$1":"$2"-"$3; print $1,$2,$3,gene[1],$4,a, b,$5,$6,$7,$12, url}' \
		> "~{OutputFile}"
		conda deactivate
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
		File poorCoverageFile = OutputFile
	}
}
