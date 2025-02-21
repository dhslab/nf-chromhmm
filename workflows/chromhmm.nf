/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { BAM_TO_BED             } from '../modules/local/bam_to_bed.nf'
include { BINARIZE_BAM           } from '../modules/local/binarize_bam.nf'
include { BINARIZE_BED           } from '../modules/local/binarize_bed.nf'
include { BINARIZE_METH          } from '../modules/local/binarize_meth.nf'
include { MERGE_BINARIES         } from '../modules/local/merge_binaries.nf'
include { MAKE_SEGMENTATION      } from '../modules/local/make_segmentation.nf'
include { OVERLAP_ENRICH         } from '../modules/local/overlap_enrich.nf'
include { FASTQC                 } from '../modules/nf-core/fastqc/main.nf'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { INPUT_CHECK            } from '../subworkflows/local/samplesheet_check.nf'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_chromhmm_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CHROMHMM {

    main:

    INPUT_CHECK(params.samplesheet)

    //
    // BINARIZE BAM
    //
    INPUT_CHECK.out.ch_bam
    .map { meta, file -> [meta.sample, meta, file] }
    .groupTuple()
    .map { sample, metaList, _ ->
        def lines = metaList.collect { meta -> "${meta.sample}\t${meta.mark}\t${meta.filename}" }
        return [ "${sample}_bam_mark_file.txt", lines.join('\n') + '\n' ]
    }
    .collectFile { fileName, content -> [ fileName, content ] }
    .map { file -> [file.baseName.tokenize("_")[0], file] }
    .set { bam_cell_mark_files }

    INPUT_CHECK.out.ch_bam
    .map { meta, file -> [meta.sample, file]}
    .groupTuple()
    .set { grouped_bams }

    binarize_bam_input = bam_cell_mark_files.combine(grouped_bams, by: 0)
    BINARIZE_BAM(binarize_bam_input)

    //
    // MAKE BED FILES FROM BAMS
    //
    //
        
    if(params.bam_to_bed) {
        GET_REGIONS(params.regions)

        INPUT_CHECK.out.ch_bam
        .map { meta, file -> [meta.id, meta, file] }
        .map { id, meta, _ ->
            def lines = "${meta.id}\t${meta.mark}\t${meta.filename}"
            return [ "${id}.bam_mark_file.txt", lines + '\n' ]
        }
        .collectFile { fileName, content -> [ fileName, content ] }
        .map { file -> [file.baseName.tokenize(".")[0], file] }
        .set { bamtobed_cellmarkfiles }

        INPUT_CHECK.out.ch_bam
        .map{meta, file -> [meta.id, file]}
        .combine(bamtobed_cellmarkfiles, by: 0)
        .set{ch_bam_to_bed}

        BAM_TO_BED(ch_bam_to_bed, GET_REGIONS.out.regions)
    }

    //
    // BINARIZE BED
    //
    INPUT_CHECK.out.ch_peak
    .map { meta, file -> [meta.sample, meta, file] }
    .groupTuple()
    .map { sample, metaList, _ ->
        def lines = metaList.collect { meta -> "${meta.sample}\t${meta.mark}\t${meta.filename}" }
        return [ "${sample}_peak_mark_file.txt", lines.join('\n') + '\n' ]
    }
    .collectFile { fileName, content -> [ fileName, content ] }
    .map { file -> [file.baseName.tokenize("_")[0], file] }
    .set { bed_cell_mark_files }

    INPUT_CHECK.out.ch_peak
    .map { meta, file -> [meta.sample, file]}
    .groupTuple()
    .set { grouped_beds }

    binarize_bed_input = bed_cell_mark_files.combine(grouped_beds, by: 0)
    BINARIZE_BED(binarize_bed_input)

    // 
    // BINARIZE METH
    //
    BINARIZE_METH(INPUT_CHECK.out.ch_meth, GET_REGIONS.out.regions_200_bp)

    //
    // MERGE BINARIES
    //
    merged_input = BINARIZE_BAM.out.bam.join(BINARIZE_BED.out.bed, by: 0).join(BINARIZE_METH.out.meth, by: 0)

    MERGE_BINARIES(merged_input)

    //
    // MAKE BINARIES
    //

    // to do: if model 10, if model 15, if model 20, do
    MAKE_SEGMENTATION(MERGE_BINARIES.out.merged_binary)

    //
    // OVERLAP ENRICHMENT
    //
    if(params.beds) {
        beds_overlap = Channel.fromPath(params.beds).splitCsv( header:true, sep:',' ).map{ row -> [row.sample,row.bed]}
        overlap_enrich = MAKE_SEGMENTATION.out.states.join(beds_overlap, by: 0)
        OVERLAP_ENRICH(overlap_enrich)
    }

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  ''  + 'pipeline_software_' +  'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

process GET_REGIONS {
        label 'process_medium'
        container "nidhidav/nf-chromhmm:v1"

        input:
        path(regions)

        output:
        path ("regions/")          , emit: regions
        path ("regions_200_bp.bed"), emit: regions_200_bp

        script:
        """
        mkdir regions
        awk -F'\\t' 'BEGIN {OFS="\\t"} {print \$1, 0, \$2}' $regions > bedtools_input.bed &&
        bedtools makewindows -b bedtools_input.bed -w 200 | awk '{if (\$3 - \$2 == 200) print \$0}' > regions_200_bp.bed &&
        for i in {1..22}; do
            cat regions_200_bp.bed | grep -w chr\$i > regions/chr\$i.regions.bed
        done
        """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
