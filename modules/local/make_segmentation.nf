process MAKE_SEGMENTATION {
    label 'process_medium'
    tag "$sample"
    container "nidhidav/nf-chromhmm:v1"
    publishDir "${params.outdir}/make_segmentation", mode: 'copy'

    input:
    tuple val(sample), path(merged_binary), path(model)

    output:
    tuple val(sample), path("segmentation*/*"), emit: states

    script:
    """
    result="segmentation_\$(echo "$model" | cut -d'.' -f1)"

    java \
    -mx80000M \
    -jar \
    ${params.chromhmm} \
    MakeSegmentation \
    $model \
    $merged_binary \
    \$result
    """
}