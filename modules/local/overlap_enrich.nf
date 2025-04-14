process OVERLAP_ENRICH {
    label 'process_medium'
    tag "$sample"
    container "nidhidav/nf-chromhmm:v1"
    publishDir "${params.outdir}/overlap_enrichment", mode: 'copy'

    input:
    tuple val(sample), path(segmentation_file), path(bed)

    output:
    path ("*png"), emit: png
    path ("*svg"), emit: svg

    script:
    """
    mkdir overlap_regions &&
    mv $bed overlap_regions/ &&

    result="\$(echo "$segmentation_file" | cut -d _ -f 1-2)_overlap"

    java \
    -mx80000M \
    -jar \
    ${params.chromhmm} \
    OverlapEnrichment \
    $segmentation_file \
    overlap_regions/ \
    \$result
    """
}