/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { GET_REGIONS            } from '../modules/local/get_regions.nf'
include { MERGE_BINARIES         } from '../modules/local/merge_binaries.nf'
include { MAKE_SEGMENTATION      } from '../modules/local/make_segmentation.nf'
include { OVERLAP_ENRICH         } from '../modules/local/overlap_enrich.nf'
include { FASTQC                 } from '../modules/nf-core/fastqc/main.nf'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { INPUT_CHECK            } from '../subworkflows/local/samplesheet_check.nf'
include { LEARN_MODEL_WF         } from '../subworkflows/local/learn_model.nf'
include { BINARIZE               } from '../subworkflows/local/binarize.nf'
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
    // MODULE: get regions
    //
    GET_REGIONS(params.regions)

    //
    // SUBWORKFLOW: binarize all input types, run bam to bed 
    //
    BINARIZE(
        INPUT_CHECK.out.ch_bam,
        INPUT_CHECK.out.ch_peak,
        INPUT_CHECK.out.ch_meth,
        GET_REGIONS.out.regions,
        GET_REGIONS.out.regions_200_bp,
        params.bam_to_bed
    )

    //
    // SUBWORKFLOW: learn model
    //
    if(params.learn_model) {
        LEARN_MODEL_WF(BINARIZE.out.merged_binaries)
    }
    
    //
    // MODULE: make segmentation
    //
    if(params.make_segmentation) {
        modelsList = params.models?.split(',') as List
        make_segmentation_input = BINARIZE.out.merged_binaries.combine(modelsList)
        MAKE_SEGMENTATION(make_segmentation_input)
    }

    //
    // MODULE: overlap enrich
    //
    if(params.beds) {
        beds_overlap = Channel.fromPath(params.beds).splitCsv( header:true, sep:',' ).map{ row -> [row.sample,row.bed]}
        overlap_enrich = MAKE_SEGMENTATION.out.states.combine(beds_overlap, by: 0)
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
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
