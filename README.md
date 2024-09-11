# MobiDL

MobidicWDL workflows

## Goals

Providing wdl workflows to treat NGS data

## Repos architecture and requirements

- Each step can be found in dedicated wdls in modules/

- A workflow imports individual wdls and run them, see panelCapture.wdl for details

- json files are provided as examples

- needs [crowmwell](https://github.com/broadinstitute/cromwell) to run

- see  [requirements](requirements.md) file for a complete list of software that need to be installed

## Validate a workflow

- requires [womtools](https://github.com/broadinstitute/cromwell/releases)

```bash

java -jar /PATH/TO/womtool.jar validate panelCapture.wdl

```

## Run

```bash

java -jar /PATH/TO/cromwell.jar run panelCapture.wdl -i panelCapture_inputs.json

```

## Workflow captainAchab

The best way to run this workflow is by using the [singularity container](https://github.com/mobidic/Achabilarity). You will find documentation about MPA and Achab [here](https://github.com/mobidic/MPA) and [here](https://github.com/mobidic/Captain-ACHAB).

## Workflow panelCapture

This workflow is dedicated to NGS experiments based on capture libraries, and focusing on gene panels/exomes. It uses  [GATK 4](https://software.broadinstitute.org/gatk/) Haplotype Caller and google [DeepVariant](https://github.com/google/deepvariant) for variant calling. Alignment output is a [crumbled](https://github.com/jkbonfield/crumble) CRAM file.

This workflow requires as input 2 fastqs and one ROI bed file.

All software paths and input paths are to be modified in the json file (example: [panelCapture_example_inputs.json](panelCapture_example_inputs.json)). All paths are absolute, except for deepvariant paths.
Indeed, DeepVariant is used in MobiDL as a singularity container, then input (Fastqs, ROI bed file) and output paths need to be bound. Inside the container, the path to bound folders is '/dv2'.
The DeepVariant singularity container has been built using this [link](https://gist.github.com/pansapiens/717efcdefb51fa0ce1a6abf092bcb2f4)
See also the [changelog](changelog.md) file.

![panelCapture workflow description](/img/panelCapture_v1.1.1.svg)
