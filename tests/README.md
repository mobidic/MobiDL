# Testing

## Requirements

- [Pytest-workflow](https://github.com/LUMC/pytest-workflow)

## Directories organization

`tests` sub-dir contains 1 `test_my_workflow.yaml` file for each tested workflow or sub-workflow

Test datas for each workflow are expected to be under `tests/my_workflow/`

<br>

## Run tests

### General syntax

```bash
pytest \
        --basetemp=/scratch
	--keep-workflow-wd \
	--verbose \
	--git-aware \
	tests/
```

Explanations (see [documentation](https://pytest-workflow.readthedocs.io/en/stable/) for details) :
* With `--basetemp=`, pytest-wf will run test inside `/scrath/<TEST_NAME>`
* Input JSON are configured so that everything lies inside `/scrath/<TEST_NAME>` (cromwell-exec + pipeline output)
* Due to `--keep-workflow-wd` option, all dirs created by pytest-wf must be be deleted *manually* afterwards
* Remove `--git-aware` if uncommited changes or outside git repo (otherwise error)


### Available tests

```bash
# Down-sampled (chr22 only) Twist exome (hg19) sample (takes ~ 20 min):
pytest \
        --tag downsampled --tag exome --tag A161161 \
        --basetemp=/scratch \
        --keep-workflow-wd \
        --verbose \
        --git-aware \
        tests/test_panelCapture.yaml &
```
