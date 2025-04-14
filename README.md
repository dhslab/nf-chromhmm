

# dhslab/chromhmm

[![GitHub Actions CI Status](https://github.com/dhslab/chromhmm/actions/workflows/ci.yml/badge.svg)](https://github.com/dhslab/chromhmm/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/dhslab/chromhmm/actions/workflows/linting.yml/badge.svg)](https://github.com/dhslab/chromhmm/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/dhslab/chromhmm)

## Introduction

**dhslab/chromhmm** is a bioinformatics pipeline that ...

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

Runs Learn Model, Make Segmentation, and/or Overlap Enrichment on provided data and models.

## Usage
First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
id,sample,mark,file
sample1_H3K27ac_1,sample1,H3K27ac,sample1_H3K27ac_1.narrowPeak
sample1_H3K27ac_2,sample1,H3K27ac,sample1_H3K27ac_2.narrowPeak
sample1_H3K27me3_1,sample1,H3K27me3,sample1_H3K27me3_1.sorted.bam
sample1_H3K27me3_2,sample1,H3K27me3,sample1_H3K27me3_2.sorted.bam
sample1_H3K36me3_1,sample1,H3K36me3,sample1_H3K36me3_1.sorted.bam
sample1_H3K36me3_2,sample1,H3K36me3,sample1_H3K36me3_2.sorted.bam
sample1_H3K4me_1,sample1,H3K4me,sample1_H3K4me_1.narrowPeak
sample1_H3K4me_2,sample1,H3K4me,sample1_H3K4me_2.narrowPeak
sample1_H3K4me3_1,sample1,H3K4me3,sample1_H3K4me3_1.narrowPeak
sample1_H3K4me3_2,sample1,H3K4me3,sample1_H3K4me3_2.narrowPeak
sample1_H3K9me3_1,sample1,H3K9me3,sample1_H3K9me3_1.narrowPeak
sample1_H3K9me3_2,sample1,H3K9me3,sample1_H3K9me3_2.narrowPeak
sample1_wgbs,sample1,methylation,sample1-wgbs.meth.bed.gz
```

The accepted file formats for the marks are: .narrowPeak, .bam, .bed.gz

Now, you can run the pipeline using:

```bash
nextflow run dhslab/nf-chromhmm \
   -profile ris \
   --samplesheet samplesheet.csv \
   --outdir <OUTDIR> \
   --make_segmentation/--learn_model
```

Additional inputs: \
   --regions: /path/to/regions \
   --models: /path/to/models \
   --states:  list of number of states \
   --beds : /path/to/bed.csv

If multiple states or regions are provided, enter them as a comma-separated list. Examples are in conf folder.

To run overlapenrichment, you need to provide a csv with a bed file with the regions of interest per sample. The sample value should match to the sample value in the samplesheet.

```csv
sample,bed
sample_1,/path/to/regions/sample_1.bed
sample_2,/path/to/regions/sample_2.bed
```

```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

dhslab/chromhmm was originally written by Nidhi.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use dhslab/chromhmm for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
