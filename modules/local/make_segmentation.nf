process MAKE_SEGMENTATION {
label 'process_medium'
tag "$sample"
container "nidhidav/nf-chromhmm:v1"
publishDir "${params.outdir}/make_segmentation", mode: 'copy'

input:
tuple val(sample), path(merged_binary)

output:
tuple val(sample), path("segmentation_results_10/*"), path("segmentation_results_15/*"), path("segmentation_results_20/*"), emit: states

script:
"""
java \
-mx80000M \
-jar \
${params.chromhmm} \
MakeSegmentation \
${params.model_10} \
$merged_binary \
segmentation_results_10

java \
-mx80000M \
-jar \
${params.chromhmm} \
MakeSegmentation \
${params.model_15} \
$merged_binary \
segmentation_results_15

java \
-mx80000M \
-jar \
${params.chromhmm} \
MakeSegmentation \
${params.model_20} \
$merged_binary \
segmentation_results_20
"""
}