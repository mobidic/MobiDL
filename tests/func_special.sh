## Global func to check 'special' files


checksum_vcf() {
	printf $(basename "$1")'\t'
	bcftools view --no-header "$1" | md5sum
}
export -f checksum_vcf


checksum_bam() {
	printf $(basename "$1")'\t'
	samtools view "$1" | md5sum
}
export -f checksum_bam


excel_to_tsv() {
	local in_xlsx=$1
	local sheet_name=$2
	/mnt/Bioinfo/Softs/bin/csvtk xlsx2csv --out-tabs --sheet-name "$sheet_name" "$in_xlsx"
}
export -f excel_to_tsv


run_wdl_MobiDL() {
	# Function to run a WDL on an inputs.json, both given as arg
	# A different config file can also be specified as an (optional) 3rd arg
	set -x

	local main_wdl=$1
	local input_json=$2
	local main_conf=/bioinfo/softs/cromwell_conf/SLURM_nodb_nocaching.conf
	if [ $# -eq 3 ]; then
		main_conf=$3
	fi

	# WARN: Clean PATH from custom stuffs:
	#       (similar to when somebody else is running pipeline)
	OLD_PATH=$PATH && PATH="/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"  # Minimal PATH

	# Activate Conda env:
	source /etc/profile.d/conda.sh && conda activate /bioinfo/conda_envs/gatk4.6Env
	local cwl_jar=/scratch/david/MobiDL/cromwell.jar

	# Actually run pipeline:
	bash /scratch/david/MobiDL/cww.sh \
		--exec "$cwl_jar" \
		--wdl "$main_wdl" \
		--input "$input_json" \
		--option /bioinfo/softs/cromwell_conf/cromwell_option_nocaching.json \
		--conf "$main_conf"
}
export -f run_wdl_MobiDL


happy_exomeTwist() {
	# Function to run hap.py on a corriel VCF sequenced on exomeTwist
	# Chromosomes are expected to have 'chr' prefix (such as for 'Exome.wdl' pipeline)
	if [ $# -lt 2 ] ; then
		echo "Problem"
		return 1
	fi
	local SAMPLE=$1  # Used to find paths of bench files (eg: 'HG002')
	local to_tested_VCF=$2  # Path to VCF produced by pipeline
	local tgt_BED=$3

	local ref_fa=/bioinfo/refData/iGenomes/Homo_sapiens/GATK/GRCh37/Sequence/WholeGenomeFasta/human_g1k_v37_decoy.fasta
	local prfx_truth=/mnt/chu-ngs/refData/VCFs_ref_for_validation
	local out_happy=out-test && mkdir --parents "$out_happy"

	source /etc/profile.d/conda.sh && conda activate /home/olivier/.conda/envs/hap.py

	# Run hap.py:
	# MEMO: hap.py will match 'chr' name itself (even if not the same between all files)
	srun --partition="test" hap.py \
		--false-positives "$prfx_truth"/"$SAMPLE"_GRCh37_1_22_v4.2.1_benchmark_noinconsistent.bed \
		--target-regions "$tgt_BED" \
		--reference "$ref_fa" \
		--report-prefix "$out_happy"/"$(basename "$to_tested_VCF" .vcf)" \
		"$prfx_truth"/"$SAMPLE"_GRCh37_1_22_v4.2.1_benchmark.vcf.gz \
		"$to_tested_VCF"
}
