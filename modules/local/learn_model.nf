// to do: take a list of state numbers, combine with all the data input that goes into learn model (tag can be state number)
// default 10,15,20
process LEARN_MODEL {
    label 'process_medium'
    tag "$states"
    container "nidhidav/nf-chromhmm:v1"
    publishDir "${params.outdir}/learnmodel", mode: 'copy'

    input:
    tuple path(merged_binary), val(states)

    output:
    path("outputdir$states"), emit: states

    script:
    """
    java \
    -mx10G \
    -jar \
    ${params.chromhmm} \
    LearnModel \
    -holdcolumnorder $merged_binary "outputdir$states" $states hg38
    """
    stub:
    """
    echo \
    "java \
    -mx10G \
    -jar \
    ${params.chromhmm} \
    LearnModel \
    -holdcolumnorder $merged_binary "outputdir$states" $states hg38"
    mkdir -p "outputdir$states"
    """
}