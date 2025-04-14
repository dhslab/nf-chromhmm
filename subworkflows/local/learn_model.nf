//
// Merge sample binary files and run learn model
//
include { LEARN_MODEL } from '../../modules/local/learn_model.nf'

workflow LEARN_MODEL_WF {

    take:
    merged_binary

    main:
    //
    // MODULE: combine merged bins
    //
    statesList = params.states?.split(',') as List
    collected_merged_binary = merged_binary.map{ id, mergedbin -> mergedbin }.collect()
    COMBINE_MERGED_BINS(collected_merged_binary)

    //
    // MODULE: learn model
    //
    learn_model_input = COMBINE_MERGED_BINS.out.combined_merged_bin.combine(statesList)
    LEARN_MODEL(learn_model_input)

}

process COMBINE_MERGED_BINS {
    label 'process_low'
    container "ghcr.io/dhslab/docker-cleutils:240229"

    input:
    path(merged_bins)

    output:
    path("combined_merged_bin"), emit: combined_merged_bin

    script:
    """
    mkdir -p combined_merged_bin
    for dir in ${merged_bins}; do
        cp "\$dir"/* combined_merged_bin/
    done
    """
}
