# MobiDL

MobidicWDL workflows

## Goals

Providing wdl workflows to treat NGS data

## Repos architecture and requirements

- Each step can be found in dedicated wdls in modules/

- A workflow imports individual wdls and run them, see panelCapture.wdl for details

- json files are provided as examples, work at mobidic institution on minimonster

- needs [crowmwell](https://github.com/broadinstitute/cromwell) to run

## Validate a workflow

- requires [womtools](https://github.com/broadinstitute/cromwell/releases)

```bash

java -jar /PATH/TO/womtool.jar validate panelCapture.wdl 

```

## Run

```bash

java -jar /PATH/TO/cromwell.jar run panelCapture.wdl -i panelCapture_inputs.json

```

## Workflow panelCapture

This workflow is dedicated to NGS experiments based on capture libraries, and focusing on gene panels.

This is suitable for exome but the VCF is hard-filtered, not VQSRed (see [here](https://software.broadinstitute.org/gatk/best-practices/workflow?id=11145).

This workflow requires as input 2 fatsqs and one ROI bed file.

All software paths and input paths are to be modified in the json file (example: panelCapture_MinifastqTest_inputs.json).

![panelCapture workflow description](/img/panelCapture.svg)
