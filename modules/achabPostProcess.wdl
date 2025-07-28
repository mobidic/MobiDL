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


task postProcess {
  meta {
		author: "Felix VANDERMEEREN"
		email: "felix.vandermeeren(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2024-07-08"
	}
  input {
    File OutAchab
    File OutAchabHTML
    String OutDir = "./"
    File? OutAchabPoorCov

    String csvtkExe = "csvtk"

		# runtime attributes
    String TaskOut  # To force exec after a given task
		String Queue
		Int Cpu
		Int Memory
  }
  String basenameOutAchabHTML = basename(OutAchabHTML, ".html")
  String basenameOutAchab = basename(OutAchab, ".xlsx")
  String OutAchabMetrix = "~{OutDir}/" + basenameOutAchab + ".metrix.tsv"
  String OutAchabPoorCovMetrix = "~{OutDir}/" + basenameOutAchab + ".poorCovMetrix.tsv"

  command <<<
    set -exo pipefail
    if [[ ! -f ~{OutDir} ]]; then
      mkdir -p ~{OutDir}
    fi

    ## Generate tabular metrix file from Achab outputs:
    (
      # Number of samples:
      # WARN: MUST use '<()' instead of 'pipe'
      #       Otherwise grep raise non-zero exit_code -> pipeFAIL -> task stop
      printf "SAMPLES_COUNT,"
      grep --count "Genotype\-" \
        <("~{csvtkExe}" xlsx2csv --sheet-index 1 "~{OutAchab}" | "~{csvtkExe}" headers)

      # Total variants:
      # (cannot be parsed directly from HTML -> Recompute it from Excel output)
      printf "ALL,"
      "~{csvtkExe}" xlsx2csv --sheet-index 1 "~{OutAchab}" |
        "~{csvtkExe}" nrows

      # Total counts for other sheets:
      # WARN: In HTML, colum order is also random..
      # ENH: Use a dedicated HTML parser
      #      Maybe the one used to write Achab HTML output
      grep --only-matching 'value=".*([0-9]\+)"' "~{OutAchabHTML}" |
        tr --delete '"' |
        tr --delete '()' |
        sed -e 's/^value=//' -e 's/ /,/'
    ) |
      "~{csvtkExe}" add-header --names Sheet,"~{basenameOutAchabHTML}" -o temp_achab_metrix.csv

    # With MultiQC 'custom_content', reports are included ONLY if they have all columns defined in 'headers' config
    # -> Add missing columns with default value 0:
    # 1) Create file with columns declared in 'custom MQC' config
    (
      echo "Sheet"
      echo "AR"
      echo "DENOVO"
    ) > wanted_columns.csv
    # 2) Outer-join with real metrix file:
    # WARN: Joint output file rows order is random -> Sort to ensure consistent column order
    "~{csvtkExe}" join --fields Sheet --outer-join --na 'NA' wanted_columns.csv temp_achab_metrix.csv |
      "~{csvtkExe}" sort --keys Sheet |
      "~{csvtkExe}" transpose --out-tabs -o "~{OutAchabMetrix}"

    ## Process 'poorCoverage.xlsx' (if provided)
    if [ -n "~{'' + OutAchabPoorCov}" ] ; then
      temp_poorCov=temp_poorCov
      occurr_threshold=5
      "~{csvtkExe}" xlsx2csv --comment-char '$' --sheet-index 1 "~{OutAchabPoorCov}" |
        sed '1s/^#//' > "$temp_poorCov".csv

      # Default outfile is one with 'NA' values
      # -> Exit prematurely if any filtering goes wrong
      {
        echo -e "subpanel\tNA"
        echo -e "~{basenameOutAchabHTML}_TOTAL\tNA"
        echo -e "~{basenameOutAchabHTML}_filt=${occurr_threshold}\tNA"
        echo -e "~{basenameOutAchabHTML}_filt-list\tNA"
      } > "~{OutAchabPoorCovMetrix}"

      # 'poorCoverage' contains only a header -> exit there:
      if [ "$("~{csvtkExe}" nrow "$temp_poorCov".csv)" -eq 0 ] ; then
        exit
      fi

      # 1) First remove genes not part of a subpanel:
      "~{csvtkExe}" grep --fields CANDIDATE --pattern '.' --invert "$temp_poorCov".csv |
        "~{csvtkExe}" replace --fields CANDIDATE --pattern '^ ' |
        "~{csvtkExe}" unfold --fields CANDIDATE --separater ' ' |
        "~{csvtkExe}" rename --fields CANDIDATE --names subpanel --out-tabs -o "$temp_poorCov".sub

      # If 'poorCoverage' has NO regions included in a subpanel -> exit there:
      if [ "$("~{csvtkExe}" nrow "$temp_poorCov".sub)" -eq 0 ] ; then
        exit
      fi

      # ENH: In following steps, ensure all subpanels are present in outfile
      #      -> Even one with '0 poorly covered regions'

      # 2) Then produce a total count of regions by sub-panel:
      "~{csvtkExe}" freq --tabs --fields subpanel "$temp_poorCov".sub |
        "~{csvtkExe}" rename --tabs --fields frequency --names "~{basenameOutAchabHTML}"_TOTAL -o "$temp_poorCov".sub.freq

      # 3) Then count and list these regions, after removing most-frequent ones:
      "~{csvtkExe}" filter2 \
        --tabs \
        --filter '$type=="OTHER" && $Occurrence<'$occurr_threshold \
        -o "$temp_poorCov".sub.filt \
        "$temp_poorCov".sub

      # If NO regions left after filtering
      # -> Send only '_TOTAL' row to final file and exit there:
      # (otherwise later 'sort .sub.filt' return 'ERROR: no data to sort')
      if [ "$("~{csvtkExe}" nrow "$temp_poorCov".sub.filt)" -eq "0" ] ; then
        "~{csvtkExe}" transpose --tabs -o "~{OutAchabPoorCovMetrix}" "$temp_poorCov".sub.freq
        exit
      fi

      "~{csvtkExe}" freq --tabs --fields subpanel "$temp_poorCov".sub.filt |
        "~{csvtkExe}" rename \
          --tabs \
          --fields frequency \
          --names "~{basenameOutAchabHTML}_filt=${occurr_threshold}" \
          -o "$temp_poorCov".sub.filt.freq

      # MEMO: 'csvtk summary -g subpanel -f gene:uniq does not preserve order
      #       -> Have to use a workaround a bit complicated
      "~{csvtkExe}" sort --tabs --keys gene "$temp_poorCov".sub.filt |
        "~{csvtkExe}" uniq --tabs --fields subpanel,gene |
        "~{csvtkExe}" summary --tabs --separater ';' --groups subpanel --fields gene:collapse |
          "~{csvtkExe}" rename \
            --tabs \
            --fields 'gene:collapse' \
            --names "~{basenameOutAchabHTML}_filt-list" \
            -o "$temp_poorCov".sub.filt.list

      # Then join everything:
      # (use 'total' as 1st file, to ensure all subpanels are present)
      "~{csvtkExe}" join \
        --tabs \
        --fields subpanel \
        --left-join --na 'NA' \
        "$temp_poorCov".sub.freq "$temp_poorCov".sub.filt.freq "$temp_poorCov".sub.filt.list |
          "~{csvtkExe}" transpose --tabs -o "~{OutAchabPoorCovMetrix}"
    fi
  >>>

  output {
    File outAchabMetrix = OutAchabMetrix
    File? outAchabPoorCovMetrix = OutAchabPoorCovMetrix
  }

  runtime {
		queue: "~{Queue}"
		cpu: "~{Cpu}"
		requested_memory_mb_per_core: "~{Memory}"
  }
}
