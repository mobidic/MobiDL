version 1.0

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
		File IntervalBedFile
		Int BedtoolsLowCoverage
		Int BedToolsSmallInterval
		File BamFile
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	command <<<
		source ~{CondaBin}activate ~{BedtoolsEnv}
		~{BedToolsExe} genomecov -ibam ~{BamFile} -bga \
		| ~{AwkExe} -v low_coverage="~{BedtoolsLowCoverage}" '~4<low_coverage' \
		| ~{BedToolsExe} intersect -a ~{IntervalBedFile} -b - \
		| ~{SortExe} -k1,1 -k2,2n -k3,3n \
		| ~{BedToolsExe} merge -c 4 -o distinct -i - \
		| ~{AwkExe} -v small_intervall="~{BedToolsSmallInterval}" \
		'BEGIN {OFS="\t";print "#chr","start","end","region","size bp","type","UCSC link"} {a=(~3-~2+1);if(a<small_intervall) {b="SMALL_INTERVAL"} else {b="OTHER"};url="http://genome-euro.ucsc.edu/cgi-bin/hgTracks?db='~{GenomeVersion}'&position="~1":"~2-10"-"~3+10"&highlight='~{GenomeVersion}'."~1":"~2"-"~3;print ~0, a, b, url}' \
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
