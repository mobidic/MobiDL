# MobiDL

MobidicWDL workflows

## Goals

Providing wdl workflows to treat NGS data

## Repos architecture and requirements

- Each step can be found in dedicated wdls in modules/

- A workflow imports individual wdls and run them, see panelCapture.wdl for details

- json files are provided as examples, work at mobidic institution on minimonster

- needs [crowmwell](https://github.com/broadinstitute/cromwell) to run

## validate a workflow

- requires [womtools](https://github.com/broadinstitute/cromwell/releases)

```bash

java -jar /PATH/TO/womtool.jar validate panelCapture.wdl 

```

## run

```bash

java -jar /PATH/TO/cromwell.jar run panelCapture.wdl -i panelCapture_inputs.json

```
