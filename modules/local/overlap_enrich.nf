process OVERLAP_ENRICH {
label 'process_medium'
tag "$sample"
container "nidhidav/nf-chromhmm:v1"
publishDir "${params.outdir}/overlap_enrichment", mode: 'copy'

input:
tuple val(sample), path(tenstates), path(fifteenstates), path(twentystates), path(bed)

output:
path ("*png"), emit: png
path ("*svg"), emit: svg

script:
"""
mkdir overlap_regions &&
mv $bed overlap_regions/ &&

java \
-mx80000M \
-jar \
${params.chromhmm} \
OverlapEnrichment \
$tenstates \
overlap_regions/ \
${sample}_10_overlap

java \
-mx80000M \
-jar \
${params.chromhmm} \
OverlapEnrichment \
$fifteenstates \
overlap_regions/ \
${sample}_15_overlap

java \
-mx80000M \
-jar \
${params.chromhmm} \
OverlapEnrichment \
$twentystates \
overlap_regions/ \
${sample}_20_overlap
"""
}