process BINARIZE_BAM {
    label 'process_medium'
    tag "$sample"
    container "nidhidav/nf-chromhmm:v1"

    input:
    tuple val(sample), path(cellmarkfile), path(bams)

    output:
    tuple val(sample), path("bambin"), emit: bam

    script:
    """
    mkdir bams
    mv *bam bams/ 
    java -mx80000M -jar ${params.chromhmm} BinarizeBam \
    -paired ${params.regions} bams/ $cellmarkfile bambin/
    """
}