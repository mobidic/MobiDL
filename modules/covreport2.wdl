version 1.0

task covreport2 {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2024-09-12"
	}
	input {
		# global variables
		String JavaExe = "java"
		String CovReport2Jar
		File? ReferenceFile
		String SampleID
		String WorkflowType
		String OutDir
		String OutDirSampleID = ""
		# task specific variables
		Int GenomeVersion = 19

		## Coverage
		Int Coverage = 30
		## Visualisation of exons
		Boolean Draw_exon_size_scaled = true
		Boolean Draw_exons_merged_same_size = false
		Boolean Merge_non_white_exons = false
		Boolean Merge_white_exons = true
		Boolean Skip_white_genes = true
		## Information on CR
		Boolean Show_file_name_abs = true
		Boolean Show_file_name_simple = true
		Boolean Show_gene_transcripts = true
		Boolean Show_gene_weighted_coverage = true
		Boolean Show_non_coding_exons = true
		Boolean Show_report_date = true
		Boolean Show_statistics = true

		String? Comments
		File GenesList
		File BamFile
		Int? Padding
		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String OutputDirSampleID = if OutDirSampleID == "" then SampleID else OutDirSampleID
	String DefaultRef = "/RefSeqExons/RefSeqExon_hg~{GenomeVersion}.txt"
	command <<<
		path_covreport=$(readlink -f ~{CovReport2Jar})
		path_covreport=$(dirname $path_covreport)

		path_pdfresults="${path_covreport}/pdf-results"

		panel=$(basename "~{GenesList}")
		panel=${panel%.*}

		if [ "~{ReferenceFile}" ]; then
			path_reference="~{ReferenceFile}";
		else
			path_reference="${path_covreport}/~{DefaultRef}";
		fi;

		if [ ~{Padding} ]; then
			reftempfile=$(mktemp);
			gawk 'BEGIN{OFS="\t"}{if(NR==1) {print $0} else {split($7,starts,",");split($8,ends,",");asort(starts);s="";for(i in starts){if(starts[i]>0){s=s""starts[i]-20","}};asort(ends);e="";for(i in ends){if(ends[i]>0){e=e""ends[i]+20","}};print $1,$2,$3,$4-20,$5+20,$6, s, e,$9}}' ${path_reference} > ${reftempfile};
			path_reference=$reftempfile;
		fi;

		configtempfile=$(mktemp)
		echo "coverage=~{Coverage}" >> ${configtempfile}
		echo "draw_exon_size_scaled=~{Draw_exon_size_scaled}" >> ${configtempfile}
		echo "draw_exons_merged_same_size=~{Draw_exons_merged_same_size}" >> ${configtempfile}
		echo "merge_non_white_exons=~{Merge_non_white_exons}" >> ${configtempfile}
		echo "merge_white_exons=~{Merge_white_exons}" >> ${configtempfile}
		echo "skip_white_genes=~{Skip_white_genes}" >> ${configtempfile}
		echo "show_file_name_abs=~{Show_file_name_abs}" >> ${configtempfile}
		echo "show_file_name_simple=~{Show_file_name_simple}" >> ${configtempfile}
		echo "show_gene_transcripts=~{Show_gene_transcripts}" >> ${configtempfile}
		echo "show_gene_weighted_coverage=~{Show_gene_weighted_coverage}" >> ${configtempfile}
		echo "show_non_coding_exons=~{Show_non_coding_exons}" >> ${configtempfile}
		echo "show_report_date=~{Show_report_date}" >> ${configtempfile}
		echo "show_statistics=~{Show_statistics}" >> ${configtempfile}

		echo "~{CovReport2Jar}"

		~{JavaExe} -jar ~{CovReport2Jar} \
			-i ~{BamFile} \
			-g ~{GenesList} \
			-r ${path_reference} \
			-p ~{SampleID} \
            ~{default="" "-comment " + Comments} \
			-config ${configtempfile}
		
		mkdir -p "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/"
		mv ${path_pdfresults}/~{SampleID}_coverage_${panel}.pdf "~{OutDir}~{OutputDirSampleID}/~{WorkflowType}/"
		
	>>>
	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
	output {
	}
}
