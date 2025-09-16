version 1.0

# MobiDL 2.0 - MobiDL 2 is a collection of tools wrapped in WDL to be used in any WDL pipelines.
# Copyright (C) 2021 MoBiDiC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

task extract {
	meta {
    author: "Felix VANDERMEEREN"
    email: "felix.vandermeeren(at)chu-montpellier.fr"
    version: "0.1.0"
    date: "2024-03-01"
  }

	input {
		String path_exe = "somalier"
		# ENH: Download correct file depending on 'genome' variable
		# WARN: Download from URL not supported by cromwell on cluster ?
		#       -> Use local file instead
		# WARN2: Once extracted, '.somalier' files are genome-build-agnostic
		#       See 'sites files' section of release
		File? sites
		String refFasta
		File bamFile
		File BamIndex
		String ext = ".bam"
		# MEMO: Somalier always name '.somalier' from BAM ReadGroup tag -> use bellow param if needed:
		String sampleName = basename(bamFile, ext)
		String outputPath = "./"

		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	command <<<
		set -eou pipefail

		if [[ ! -d ~{outputPath} ]]; then
			mkdir --parents ~{outputPath}
		fi
		# Then run 'somalier extract'
		# MEMO: Use method described here https://github.com/brentp/somalier/issues/115#issuecomment-1593541868
		#       To enforce naming of outfile as 'sample.somalier'
		#       Mostly for Sarek data, where CRAM read-group is 'sample_sample'
		#       Leading somalier to create a 'sample_sample.somalier' (instead of expected 'sample.somalier')
		SOMALIER_SAMPLE_NAME=~{sampleName} "~{path_exe}" extract \
			--sites="~{sites}" \
			--fasta="~{refFasta}" \
			--out-dir="~{outputPath}" \
			"~{bamFile}"
	>>>

	output {
		File file = "~{outputPath}/" + sampleName + ".somalier"
	}

	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
}


task relate {
	meta {
    author: "Felix VANDERMEEREN"
    email: "felix.vandermeeren(at)chu-montpellier.fr"
    version: "0.0.4"
    date: "2024-03-14"
  }

	input {
		String path_exe = "somalier"
		Array[File]+ somalier_extracted_files
		File? ped
		String outputPath = "./"
        String csvtkExe = "csvtk"

		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String ped_or_infer = if defined(ped) then "--ped=uniq_samplID.ped" else "--infer"
	String relatedPrefix = "~{outputPath}/related"
	String relateSamplesFile = "~{relatedPrefix}.samples.tsv"
	String relatePairsFile = "~{relatedPrefix}.pairs.tsv"

	command <<<
		set -eou pipefail

		if [[ ! -d "~{outputPath}" ]]; then
			mkdir --parents "~{outputPath}"
		fi

		# Bellow condition should be:
		# * Empty string, if 'ped' NOT defined -> if FALSE -> do NOT run 'csvtk uniq'
		# * Not empty string, if 'ped' defined -> if TRUE -> RUN 'csvtk uniq'
		if [ -n "~{'' + ped}" ] ; then
			## 'somalier relate' does not allow duplicate sampleID in PED (case for pooled parents)
			# -> Uniq by sampleID (= column #2)
			# WARN: With bellow method, a pool with '3F + 1M' can have 'ped_sex=F' (if order is not favorable)
			#       In any case, PED file is very sensible to order:
			#       Eg. if proband is placed last and a sib or parent is 'affected', it will be considered proband (instead of the true proband)
			"~{csvtkExe}" uniq \
				--tabs --comment-char '$' \
				--fields 2 \
				-o uniq_samplID.ped \
				"~{ped}"
		fi

		## Run 'somalier relate'
		"~{path_exe}" relate \
			~{ped_or_infer} \
			--output-prefix="~{relatedPrefix}" \
			~{sep=" " somalier_extracted_files}
	>>>

	output {
		File RelateSamplesFile = relateSamplesFile
        File RelatePairsFile = relatePairsFile
	}

	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
}


task relatePostprocess {
	meta {
    author: "Felix VANDERMEEREN"
    email: "felix.vandermeeren(at)chu-montpellier.fr"
    version: "0.0.1"
    date: "2024-06-21"
  }

	input {
		File relateSamplesFile
		File relatePairsFile
		File? ped
		String outputPath = "./"
		String csvtkExe = "csvtk"

		#Thresholds used bellow:
		Float maxYforFemale = 0.5  # Bellow this value -> sample predicted as 'female' (otherwise 'male')
		Float minHomConcordForRelated = 0.6  # Above this value -> pair of samples predicted as 'related'

		# runtime attributes
		String Queue
		Int Cpu
		Int Memory
	}
	String postProcessPrefix = "~{outputPath}/related"
	String customSamplesFile = "~{postProcessPrefix}.samples.custom.tsv"
	String relateFilteredPairs = "~{postProcessPrefix}.pairs.filtered.tsv"

	command <<<
		set -eoux pipefail

		## A) Post-process 'relate.samples.tsv' to create a custom one with more info:
		temp_custom=somalier_relate.custom.tmp  # Prefix of temporary file

		# ...With expected ploidy (if NO input PED provided, default value = -9):
		ploidy_tmp=expected_ploidy.tsv
		# Bellow condition should be:
		# * Empty string, if 'ped' NOT defined -> if FALSE -> do NOT run 'csvtk uniq'
		# * Not empty string, if 'ped' defined -> if TRUE -> RUN 'csvtk uniq'
		if [ -n "~{'' + ped}" ] ; then
			## Compute expected ploidy (+ rename 'frequency' column):
			"~{csvtkExe}" freq \
				--tabs --comment-char '$' \
				--fields IndivID \
				"~{ped}" |
				"~{csvtkExe}" rename \
					--tabs \
					--fields frequency --names ploidy_attendue \
					-o "$ploidy_tmp"

			if [ -n "$(awk 'NR>1 {print $2}' "~{ped}" | sort | uniq --repeated)" ] ; then  # If duplicated indivID in PED (ie pools)
				# >> TEMP_SOLUCE
				#    Re-calculate expected relatedness from PED
				#    (not needed when Somalier allow duplicated sampleID if famID differ)
				recomputed_relatedness=expected_relatedness2.tsv
				sed '1s/^#//' "~{ped}" |
					awk -F"\t" '$3!=0 || $4!=0' |
					"~{csvtkExe}" mutate2 -t -n parent -e '$PereID + ";" + $MereID' |
					"~{csvtkExe}" unfold -t -s';' -f parent |
					"~{csvtkExe}" grep -t -f parent -v -p 0 |
					"~{csvtkExe}" cut -t -f IndivID,parent |
					"~{csvtkExe}" mutate2 -t -n expected_relatedness -e "'0.5'" |
					sed '1s/^/#/' > "$recomputed_relatedness".tmp
				# Add same rows, but inverting columns 'Parent' (as 1st) and 'IndivID' (as 2nd)
				# MEMO: Doing that make 'join -f c1,c2' result in a '-f c1==val1 OR c2==val2' operation
				#       (by default it has a 'c1==val1 AND c2==val2' behaviour)
				#       See run 'DI014' as example
				{
					cat "$recomputed_relatedness".tmp
					"~{csvtkExe}" cut -Ht -f 2,1,3 "$recomputed_relatedness".tmp
				} > "$recomputed_relatedness"
				# Add empty row for later join to work even if no 'parent-child' relation found in PED:
				echo -e "\t\t" >> "$recomputed_relatedness"
				# << TEMP_SOLUCE
			fi

		else
			# Create dummy expected_ploidy, with only header + 1 empty row:
			# (for later join to work even for 'somalier relate --infer')
			echo -e "IndivID\tploidy_attendue" > "$ploidy_tmp"
			echo -e "\t" >> "$ploidy_tmp"  # Add empty row (required for later join to work as expected)
		fi


		# ...With 'sample_id' column moved at 1st position of column order (required for multiQC):
		# (1st remove annoying '#' at beggining)
		sed '1s/^#//' "~{relateSamplesFile}" > "$temp_custom"
		"~{csvtkExe}" cut \
			--tabs \
			-f sample_id,$("~{csvtkExe}" headers -t "$temp_custom" | awk '$0 != "sample_id"' | "~{csvtkExe}" transpose) \
			-o "$temp_custom".reordered \
			"$temp_custom"

		"~{csvtkExe}" join \
			--tabs \
			--left-join --na '-9' \
			--fields 'sample_id;IndivID' \
			-o "$temp_custom".reordered.ploidy \
			"$temp_custom".reordered expected_ploidy.tsv

		# ...With new column 'estimated_ploidy' computed from different columns:
		# ENH: Instead do this through 'modify' attribute of multiQC config ?
		# MEMO: If no '-p/--pattern' provided, 'csvtk mutate' will copy column
		# INFO: Use 'csvtk round' to have estimated_ploidy as integer
		"~{csvtkExe}" mutate2 \
			--tabs \
			--expression '$n_hom_alt / ($n_hom_alt + $n_het + $n_hom_ref)' \
			--name fraction_hom_alt \
			"$temp_custom".reordered.ploidy |
				"~{csvtkExe}" mutate2 \
					--tabs \
					--name transform \
					--expression '-13.8 * $fraction_hom_alt + 5.58' \
					--at 2 |
						"~{csvtkExe}" mutate \
							--tabs \
							--fields transform \
							--name estimated_ploidy |
								"~{csvtkExe}" round \
									--tabs \
									--fields estimated_ploidy \
									--decimal-width 0 |
										"~{csvtkExe}" mutate2 \
											--tabs \
											--name valid_ploidy \
											--expression '($ploidy_attendue != -9 && $ploidy_attendue == $estimated_ploidy) ? "pass" : "fail"' \
											-o "$temp_custom".reordered.ploidy.fraction

		# ...With a column comparing 'pedigree_sex' with 'inferred_sex':
		#
		# MEMO: '(inferred_)sex' made by somalier does not work very_well with pools
		#       -> instead deduce sex from 'Scaled mean depth on Y'
		#       -> Cut-off is chosen so that a pool of 3 individuals with '2 F + 1 M' with will be predicted 'female'
		#
		# WARN: '0.6' can missgender a pool of 4 individuals with 3F + 1M
		#       (eg: 'Pool16_Mixte' from DI016, predicted as 'male' when we would expect 'female')
		#
		# ENH: Instead do this through 'modify' attribute of multiQC config ?
		#
		"~{csvtkExe}" mutate2 \
			--tabs \
			--name sexY \
			--expression '($Y_depth_mean < ~{maxYforFemale}) ? "female" : "male"' \
			"$temp_custom".reordered.ploidy.fraction |
				"~{csvtkExe}" mutate2 \
					--tabs \
					--name valid_sex \
					--expression '($original_pedigree_sex != -9 && $original_pedigree_sex == $sexY) ? "pass" : "fail"' \
					-o "~{customSamplesFile}"

		## B) Post-process relate.pairs.tsv to create a 'filered' version of it:
		# Containing pairs with expected relatedness or high 'homozygous_concordance'
		# Can be used to highlight 'abnormal' relationships
		# (= declared in PED but low 'hom_concord' or undeclared in PED but high 'hom_concord')
		#
		# Bellow use 'csvtk mutate2 with ternary operator' to add 'pass/fail'
		# ENH: Instead do this through 'modify' attribute of multiQC config ?
		#
		# WARN: With 'expected_relatedness != -1', we would catch 'child-parent' relationships (= 0.5)
		#       But also 'sib-sib' relationships (= 0.490000...)
		#       -> As 'sib-sib' have '0.55 < hom_concord < 0.6', exclude them using 'expected_relatedness == 0.5'
		#
		# ENH: Replace expected_relatedness value by 'child-parent' (and 'sib-sib' if supported)
		# ENH: Add family_ID, when pair of well related samples
		#
		source_for_filtered="~{relatePairsFile}"

		# >> TEMP_SOLUCE
		# Replace original col 'expected_relatedness' with recomputed one:
		# WARN: Do that only if:
		# * PED defined
		# * 'pairs.tsv' has at least 1 record
		# * PED show duplicated 'indivID' (ie pools)
		#
		if [ -n "~{'' + ped}" ] && [ $("~{csvtkExe}" nrow -C'$' "~{relatePairsFile}") -gt 0 ] && [ -n "$(awk 'NR>1 {print $2}' "~{ped}" | sort | uniq --repeated)" ] ; then
			source_for_filtered=temp_relatedness.tsv
			"~{csvtkExe}" join \
				-t -C'$' \
				--left-join --na '-1.0' \
				-f '1,2;1,2' \
				-o "$source_for_filtered" \
				<("~{csvtkExe}" cut -t -C'$' -f -expected_relatedness "~{relatePairsFile}") "$recomputed_relatedness"
		fi
		# << TEMP_SOLUCE

		sed '1s/^#//' "$source_for_filtered" |
			"~{csvtkExe}" filter2 \
				--tabs \
				--filter '$expected_relatedness == 0.5 || $hom_concordance > ~{minHomConcordForRelated}' \
				--show-row-number |
				"~{csvtkExe}" mutate2 \
					--tabs \
					--name valid_relationship \
					--expression '($expected_relatedness == 0.5 && $hom_concordance > ~{minHomConcordForRelated}) ? "pass" : "fail"' \
					-o "~{relateFilteredPairs}"
	>>>

	output {
		File CustomSamplesFile = customSamplesFile
		File RelateFilteredPairs = relateFilteredPairs
	}

	runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
	}
}
